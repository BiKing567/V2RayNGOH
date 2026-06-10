import AbilityStage from '@ohos.app.ability.AbilityStage';
import { initStorage } from '../utils/Storage';
import * as Logger from '../utils/Logger';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    super.onCreate();
    Logger.i('AbilityStage onCreate');
    initStorage(this.context);
  }
}
