import ExtensionAbility from '@ohos.app.ability.ExtensionAbility';
import { CoreServiceManager, ServiceMode } from './CoreServiceManager';
import * as Logger from '../utils/Logger';

export default class ProxyServiceAbility extends ExtensionAbility {
  onCreate(want): void {
    Logger.i('ProxyServiceAbility onCreate');
  }

  onRequest(want, startId): void {
    Logger.i('ProxyServiceAbility onRequest');
    CoreServiceManager.start(ServiceMode.PROXY);
  }

  onConnect(want): object {
    Logger.i('ProxyServiceAbility onConnect');
    return {};
  }

  onDisconnect(want): void {
    Logger.i('ProxyServiceAbility onDisconnect');
    CoreServiceManager.stop();
  }

  onDestroy(): void {
    Logger.i('ProxyServiceAbility onDestroy');
    CoreServiceManager.stop();
  }
}
