import ExtensionAbility from '@ohos.app.ability.ExtensionAbility';
import { CoreServiceManager, ServiceMode } from './CoreServiceManager';
import * as Logger from '../utils/Logger';

let vpnConnection: object | null = null;

export default class VpnServiceAbility extends ExtensionAbility {
  onCreate(want): void {
    Logger.i('VpnServiceAbility onCreate');
  }

  onRequest(want, startId): void {
    Logger.i('VpnServiceAbility onRequest');
    CoreServiceManager.start(ServiceMode.VPN);
  }

  onConnect(want): object {
    Logger.i('VpnServiceAbility onConnect');
    return {};
  }

  onDisconnect(want): void {
    Logger.i('VpnServiceAbility onDisconnect');
    CoreServiceManager.stop();
  }

  onDestroy(): void {
    Logger.i('VpnServiceAbility onDestroy');
    CoreServiceManager.stop();
    if (vpnConnection) {
      try {
        (vpnConnection as Record<string, () => void>).stopVpn?.();
      } catch (e) {
        Logger.e('Error stopping VPN: ' + JSON.stringify(e));
      }
      vpnConnection = null;
    }
  }
}
