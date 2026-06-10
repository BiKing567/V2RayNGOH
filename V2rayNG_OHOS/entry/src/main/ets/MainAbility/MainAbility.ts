import UIAbility from '@ohos.app.ability.UIAbility';
import Window from '@ohos.window';
import { initStorage } from '../utils/Storage';
import * as Logger from '../utils/Logger';
import * as V2rayCore from '../natives/V2rayCore';

export default class MainAbility extends UIAbility {
  onCreate(want, launchParam): void {
    Logger.i('MainAbility onCreate');
    initStorage(this.context);
  }

  onDestroy(): void {
    Logger.i('MainAbility onDestroy');
    V2rayCore.stopCore();
  }

  onWindowStageCreate(windowStage: Window.WindowStage): void {
    Logger.i('MainAbility onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err && err.code !== 0) {
        Logger.e('Failed to load content: ' + JSON.stringify(err));
      }
    });

    const ver = V2rayCore.getVersion();
    Logger.i('V2Ray core version: ' + ver);
  }

  onWindowStageDestroy(): void {
    Logger.i('MainAbility onWindowStageDestroy');
    V2rayCore.stopCore();
  }

  onForeground(): void {
    Logger.i('MainAbility onForeground');
  }

  onBackground(): void {
    Logger.i('MainAbility onBackground');
  }
}
