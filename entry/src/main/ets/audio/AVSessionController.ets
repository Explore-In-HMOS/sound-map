import { common, wantAgent } from '@kit.AbilityKit'
import { avSession } from '@kit.AVSessionKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { resourceManager } from '@kit.LocalizationKit'
import { MediaTools } from '../audio/MediaTools'
import { MusicModel } from '../common/model/MusicModel'

export const audioDomain: number = 0xFF00
export const audioPrefix: string = 'MusicPlay'


export interface IMediaController {
  getFirst(): boolean
  startByIndex(index?: number): void | Promise<void>
  resume(): void | Promise<void>
  pause(): void | Promise<void>
  playNext(): void | Promise<void>
  playPrevious(): void | Promise<void>
  seek(ms: number): void
}

export class AVSessionController {
  private context?: common.UIAbilityContext
  private session?: avSession.AVSession
  private mediaController?: IMediaController
  private musicList: MusicModel[] = []
  private musicIndex: number = 0

  constructor() {
    const list = AppStorage.get('musicList') as MusicModel[] | undefined
    if (list) {
      this.musicList = list
    }
    this.init()
  }

  public static getInstance(): AVSessionController {
    let instance = AppStorage.get('AVSessionController') as AVSessionController
    if (!instance) {
      instance = new AVSessionController()
      AppStorage.setOrCreate('AVSessionController', instance)
    }
    return instance
  }

  private async init(): Promise<void> {
    this.context = AppStorage.get('context')
    this.mediaController = AppStorage.get('mediaController')

    if (!this.context || !this.mediaController) {
      return
    }

    const session = await avSession.createAVSession(
      this.context,
      'PLAY_AUDIO',
      'audio'
    )

    this.session = session
    await session.activate()

    await session.setAVMetadata({
      assetId: '0',
      title: 'Unknown',
      artist: 'Unknown',
      author: 'Unknown',
      duration: 0,
      mediaImage: undefined
    })

    await session.setAVPlaybackState({
      state: avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      position: {
        elapsedTime: 0,
        updateTime: Date.now()
      }
    })

    this.bindLaunchAbility()
    this.bindSessionCallbacks()
  }

  private bindLaunchAbility(): void {
    if (!this.context || !this.session) {
      return
    }

    const wantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    } as wantAgent.WantAgentInfo

    wantAgent.getWantAgent(
      wantAgentInfo,
      (err: Error | null, agent: object) => {
        if (err) {
          hilog.error(audioDomain, audioPrefix, 'getWantAgent failed')
          return
        }
        this.session?.setLaunchAbility(agent)
      }
    )
  }

  private bindSessionCallbacks(): void {
    if (!this.session) {
      return
    }

    this.session.on('play', () => {
      if (this.mediaController?.getFirst()) {
        this.mediaController.startByIndex()
      } else {
        this.mediaController?.resume()
      }
    })

    this.session.on('pause', () => {
      this.mediaController?.pause()
    })

    this.session.on('stop', () => {
      this.mediaController?.pause()
    })

    this.session.on('playNext', () => {
      this.mediaController?.playNext()
    })

    this.session.on('playPrevious', () => {
      this.mediaController?.playPrevious()
    })

    this.session.on('seek', (ms: number) => {
      this.mediaController?.seek(ms)
    })
  }

  public async updateMetadata(): Promise<void> {
    if (!this.context || !this.session) {
      return
    }

    this.musicIndex = AppStorage.get('selectIndex') ?? 0

    try {
      const mediaImage = await MediaTools.getPixelMapFromResource(
        this.context,
        this.musicList[this.musicIndex].artwork as resourceManager.Resource
      )

      await this.session.setAVMetadata({
        assetId: `${this.musicIndex}`,
        title: this.musicList[this.musicIndex].title,
        artist: this.musicList[this.musicIndex].artist,
        mediaImage,
        duration: this.getDuration()
      })
    } catch {
      hilog.error(audioDomain, audioPrefix, 'updateMetadata failed')
    }
  }

  public updateProgress(ms: number): void {
    this.session?.setAVPlaybackState({
      position: {
        elapsedTime: ms,
        updateTime: Date.now()
      }
    })
  }

  public updatePlayState(isPlay: boolean): void {
    this.session?.setAVPlaybackState({
      state: isPlay
        ? avSession.PlaybackState.PLAYBACK_STATE_PLAY
        : avSession.PlaybackState.PLAYBACK_STATE_PAUSE
    })
  }

  private getDuration(): number {
    return AppStorage.get('totalMsTime') ?? -1
  }

  public unregister(): void {
    if (!this.session) {
      return
    }
    this.session.off('play')
    this.session.off('pause')
    this.session.off('playNext')
    this.session.off('playPrevious')
    this.session.off('seek')
  }

  public setPlayState(isPlay: boolean): void {
    this.updatePlayState(isPlay)
  }

  public unregisterSessionListener(): void {
    this.unregister()
  }

}
