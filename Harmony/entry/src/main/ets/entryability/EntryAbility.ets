import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { FlutterManager } from '@ohos/flutter_ohos';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FlutterManager.getInstance().pushUIAbility(this)
    hilog.info(DOMAIN, 'Harmony', 'EntryAbility onCreate')
  }

  onDestroy(): void {
    FlutterManager.getInstance().popUIAbility(this)
    hilog.info(DOMAIN, 'Harmony', 'EntryAbility onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    FlutterManager.getInstance().pushWindowStage(this, windowStage)
    windowStage.loadContent('pages/Index')
  }

  onWindowStageDestroy(): void {
    FlutterManager.getInstance().popWindowStage(this)
  }
}
