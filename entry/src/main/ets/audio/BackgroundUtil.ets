import type common from '@ohos.app.ability.common'
import { wantAgent } from '@kit.AbilityKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { audioDomain, audioPrefix } from './AVSessionController'

const TAG = 'BackgroundUtil'

export class BackgroundUtil {

  public static startContinuousTask(context?: common.UIAbilityContext): void {
    if (!context) {
      hilog.error(audioDomain, audioPrefix, `${TAG}: context is undefined`)
      return
    }

    const wantAgentInfo = {
      wants: [
        {
          bundleName: context.abilityInfo.bundleName,
          abilityName: context.abilityInfo.name
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    } as wantAgent.WantAgentInfo

    wantAgent.getWantAgent(
      wantAgentInfo,
      (err: BusinessError | null, agent: object) => {
        if (err) {
          hilog.error(
            audioDomain,
            audioPrefix,
            `${TAG}: getWantAgent failed, code=${err.code}, msg=${err.message}`
          )
          return
        }

        backgroundTaskManager
          .startBackgroundRunning(
            context,
            backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
            agent
          )
          .then(() => {
            hilog.info(
              audioDomain,
              audioPrefix,
              `${TAG}: startBackgroundRunning succeeded`
            )
          })
          .catch((error: BusinessError) => {
            hilog.error(
              audioDomain,
              audioPrefix,
              `${TAG}: startBackgroundRunning failed, code=${error.code}, msg=${error.message}`
            )
          })
      }
    )
  }

  public static stopContinuousTask(context?: common.UIAbilityContext): void {
    if (!context) {
      hilog.error(audioDomain, audioPrefix, `${TAG}: context is undefined`)
      return
    }

    backgroundTaskManager
      .stopBackgroundRunning(context)
      .then(() => {
        hilog.info(
          audioDomain,
          audioPrefix,
          `${TAG}: stopBackgroundRunning succeeded`
        )
      })
      .catch((error: BusinessError) => {
        hilog.error(
          audioDomain,
          audioPrefix,
          `${TAG}: stopBackgroundRunning failed, code=${error.code}, msg=${error.message}`
        )
      })
  }
}
