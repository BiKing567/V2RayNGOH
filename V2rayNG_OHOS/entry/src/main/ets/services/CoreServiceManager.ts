import * as V2rayCore from '../natives/V2rayCore';
import { ProfileItem } from '../model/ProfileItem';
import { EConfigType } from '../model/Enums';
import { ConfigBuilder } from '../utils/ConfigBuilder';
import * as Storage from '../utils/Storage';
import * as Logger from '../utils/Logger';

export enum ServiceState {
  NOT_RUNNING,
  RUNNING,
  STARTING,
  STOPPING,
}

export enum ServiceMode {
  VPN,
  PROXY,
}

export interface ServiceCallbacks {
  onStateChange(state: ServiceState): void;
  onSpeedUpdate(uplink: number, downlink: number): void;
  onDelayResult(delay: number): void;
  onError(message: string): void;
}

class CoreServiceManagerImpl {
  private state: ServiceState = ServiceState.NOT_RUNNING;
  private mode: ServiceMode = ServiceMode.PROXY;
  private currentProfile: ProfileItem | null = null;
  private callbacks: ServiceCallbacks | null = null;
  private socksPort: number = 10808;
  private trafficInterval: number | null = null;
  private vpnService: any = null;
  private proxyService: any = null;

  registerCallbacks(cb: ServiceCallbacks): void {
    this.callbacks = cb;
  }

  unregisterCallbacks(): void {
    this.callbacks = null;
  }

  async start(mode: ServiceMode, profileGuid?: string): Promise<void> {
    if (this.state === ServiceState.RUNNING) {
      Logger.w('Service already running');
      return;
    }

    this.setState(ServiceState.STARTING);
    this.mode = mode;

    try {
      const guid = profileGuid || await Storage.getSelectedServer();
      if (!guid) {
        throw new Error('No server selected');
      }

      const profile = await Storage.loadServer(guid);
      if (!profile) {
        throw new Error('Failed to load server config');
      }

      // Refresh socks port
      this.socksPort = 10808;

      this.currentProfile = profile;
      const configJson = ConfigBuilder.buildV2RayConfig(
        profile,
        this.socksPort,
        mode === ServiceMode.VPN ? 'vpn' : 'proxy',
      );

      Logger.i('Starting V2Ray core with config:\n' + configJson);

      if (mode === ServiceMode.VPN) {
        await this.startVpnService(configJson);
      } else {
        await this.startProxyService(configJson);
      }

      this.setState(ServiceState.RUNNING);
      this.startTrafficMonitor();
    } catch (err) {
      Logger.e('Failed to start service: ' + JSON.stringify(err));
      this.setState(ServiceState.NOT_RUNNING);
      if (this.callbacks) {
        this.callbacks.onError('Failed to start: ' + (err as Error).message);
      }
    }
  }

  async stop(): Promise<void> {
    if (this.state !== ServiceState.RUNNING) return;

    this.setState(ServiceState.STOPPING);
    this.stopTrafficMonitor();

    try {
      V2rayCore.stopCore();
      if (this.vpnService) {
        await this.vpnService.stopVpn();
        this.vpnService = null;
      }
      if (this.proxyService) {
        await this.proxyService.stopProxy();
        this.proxyService = null;
      }
    } catch (err) {
      Logger.e('Error stopping service: ' + JSON.stringify(err));
    }

    this.setState(ServiceState.NOT_RUNNING);
  }

  getState(): ServiceState {
    return this.state;
  }

  getMode(): ServiceMode {
    return this.mode;
  }

  getCurrentProfile(): ProfileItem | null {
    return this.currentProfile;
  }

  async measureDelay(): Promise<number> {
    if (this.state !== ServiceState.RUNNING) return -1;
    const testUrl = (await Storage.getSetting('delay_test_url')) || 'https://www.gstatic.com/generate_204';
    try {
      const result = V2rayCore.measureDelay(testUrl);
      if (this.callbacks) {
        this.callbacks.onDelayResult(result);
      }
      return result;
    } catch {
      return -1;
    }
  }

  private setState(state: ServiceState): void {
    this.state = state;
    if (this.callbacks) {
      this.callbacks.onStateChange(state);
    }
  }

  private async startVpnService(configJson: string): Promise<void> {
    V2rayCore.startCore(configJson, 0);
    Logger.i('VPN mode started');
  }

  private async startProxyService(configJson: string): Promise<void> {
    V2rayCore.startCore(configJson, 0);
    Logger.i('Proxy mode started');
  }

  private startTrafficMonitor(): void {
    this.trafficInterval = setInterval(() => {
      try {
        const stats = V2rayCore.queryTraffic();
        if (stats && this.callbacks) {
          const lines = stats.split(';');
          let uplink = 0;
          let downlink = 0;
          for (const line of lines) {
            if (!line) continue;
            const parts = line.split(',');
            if (parts.length === 3) {
              if (parts[1] === 'uplink') uplink += parseInt(parts[2]);
              if (parts[1] === 'downlink') downlink += parseInt(parts[2]);
            }
          }
          this.callbacks.onSpeedUpdate(uplink, downlink);
        }
      } catch {
        // ignore
      }
    }, 2000) as unknown as number;
  }

  private stopTrafficMonitor(): void {
    if (this.trafficInterval !== null) {
      clearInterval(this.trafficInterval);
      this.trafficInterval = null;
    }
  }
}

export const CoreServiceManager = new CoreServiceManagerImpl();
