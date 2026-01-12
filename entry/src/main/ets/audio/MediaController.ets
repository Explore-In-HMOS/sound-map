import { common } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { audioDomain, audioPrefix, AVSessionController } from './AVSessionController';
import { MediaTools } from '../audio/MediaTools';
import { MusicModel } from '../common/model/MusicModel';
import { BackgroundUtil } from './BackgroundUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';


export interface IMediaController {
  getFirst(): boolean
  startByIndex(index?: number): void | Promise<void>
  resume(): void | Promise<void>
  pause(): void | Promise<void>
  playNext(): void | Promise<void>
  playPrevious(): void | Promise<void>
  seek(ms: number): void
  release(): void | Promise<void>
}


export class MediaController implements IMediaController {
  private player?: media.AVPlayer;
  private context?: common.UIAbilityContext = AppStorage.get('context');
  private musicList: MusicModel[] = [];
  private avSessionController?: AVSessionController;
  private musicIndex = 0;
  private isFirst = true;

  constructor() {
    const list = AppStorage.get('musicList') as MusicModel[];
    if (list) {
      this.musicList = list;
    }
    this.initAVPlayer();
  }

  public static getInstance(): MediaController {
    let instance = AppStorage.get('mediaController') as MediaController;
    if (!instance) {
      instance = new MediaController();
      AppStorage.setOrCreate('mediaController', instance);
    }
    return instance;
  }

private async initAVPlayer() {
  this.player = await media.createAVPlayer();

  this.player.audioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
    rendererFlags: 0
  };

  this.player.on('audioInterrupt', (interruptEvent: audio.InterruptEvent) => {
    if (interruptEvent.forceType === audio.InterruptForceType.INTERRUPT_FORCE) {
      switch (interruptEvent.hintType) {
        case audio.InterruptHint.INTERRUPT_HINT_PAUSE:
          this.pause();
          break;

        case audio.InterruptHint.INTERRUPT_HINT_STOP:
          this.pause();
          break;

        case audio.InterruptHint.INTERRUPT_HINT_DUCK:
          break;

        case audio.InterruptHint.INTERRUPT_HINT_UNDUCK:
          break;

        default:
          break;
      }
    } else if (
      interruptEvent.forceType === audio.InterruptForceType.INTERRUPT_SHARE &&
        interruptEvent.hintType === audio.InterruptHint.INTERRUPT_HINT_RESUME
    ) {
      this.resume();
    }
  });

  this.player.on('audioOutputDeviceChangeWithInfo', () => {
  });

  this.avSessionController = AVSessionController.getInstance();
}


  getFirst(): boolean {
    return this.isFirst;
  }

  async startByIndex(index: number = this.musicIndex) {
    this.musicIndex = index;
    this.isFirst = false;
    await this.loadSongUrl();
  }

  async resume() {
    await this.player?.play();
    this.avSessionController?.setPlayState(true);
  }

  async pause() {
    await this.player?.pause();
    this.avSessionController?.setPlayState(false);
  }

  playNext() {
    this.startByIndex(this.musicIndex + 1 >= this.musicList.length ? 0 : this.musicIndex + 1);
  }

  playPrevious() {
    this.startByIndex(this.musicIndex - 1 < 0 ? this.musicList.length - 1 : this.musicIndex - 1);
  }

  seek(ms: number) {
    this.player?.seek(ms);
  }

  private async loadSongUrl() {
    if (!this.player || !this.context) {
      return;
    }
    await this.player.reset();
    this.player.fdSrc = await MediaTools.getAVFileDescriptor(
      this.context,
      this.musicList[this.musicIndex].src
    );
    await this.player.play();
  }

  public async release() {
    if (!this.player || !this.context) {
      return;
    }

    try {
      await this.player.release();
      this.avSessionController?.unregisterSessionListener();
      BackgroundUtil.stopContinuousTask(this.context);
    } catch (e) {
      hilog.error(audioDomain, audioPrefix, 'MediaController release failed');
    }
  }

}
