import { EConfigType, configTypeFromInt } from './Enums';

export class ProfileItem {
  configVersion: number = 4;
  configType: EConfigType;
  subscriptionId: string = '';
  addedTime: number = Date.now();

  remarks: string = '';
  description?: string;
  server?: string;
  serverPort?: string;

  password?: string;
  method?: string;
  flow?: string;
  username?: string;

  network?: string;
  headerType?: string;
  host?: string;
  path?: string;
  seed?: string;
  kcpMtu?: number;
  kcpTti?: number;

  quicSecurity?: string;
  quicKey?: string;
  mode?: string;
  serviceName?: string;
  authority?: string;
  xhttpMode?: string;
  xhttpExtra?: string;
  finalMask?: string;
  security?: string;
  sni?: string;
  alpn?: string;
  fingerPrint?: string;
  insecure?: boolean;
  echConfigList?: string;
  verifyPeerCertByName?: string;
  pinnedCA256?: string;

  publicKey?: string;
  shortId?: string;
  spiderX?: string;
  mldsa65Verify?: string;

  secretKey?: string;
  preSharedKey?: string;
  localAddress?: string;
  reserved?: string;
  mtu?: number;

  obfsPassword?: string;
  portHopping?: string;
  portHoppingInterval?: string;
  pinSHA256?: string;
  bandwidthDown?: string;
  bandwidthUp?: string;

  policyGroupType?: string;
  policyGroupSubscriptionId?: string;
  policyGroupFilter?: string;
  proxyChainProfiles?: string;

  browserDialerMode?: string;

  constructor(configType: EConfigType) {
    this.configType = configType;
  }

  getServerAddressAndPort(): string {
    if (!this.server && this.configType === EConfigType.CUSTOM) {
      return '127.0.0.1:10808';
    }
    return this.getIpv6Address(this.server) + ':' + this.serverPort;
  }

  private getIpv6Address(addr?: string): string {
    if (!addr) return '';
    if (addr.includes(':')) {
      return `[${addr}]`;
    }
    return addr;
  }

  toJSON(): Record<string, Object> {
    const result: Record<string, Object> = {};
    const self: Record<string, Object> = this as unknown as Record<string, Object>;
    for (const key of Object.keys(this)) {
      result[key] = self[key];
    }
    return result;
  }

  static fromJSON(json: Record<string, Object>): ProfileItem {
    const item = new ProfileItem(configTypeFromInt(json['configType'] as number));
    Object.assign(item, json);
    return item;
  }
}
