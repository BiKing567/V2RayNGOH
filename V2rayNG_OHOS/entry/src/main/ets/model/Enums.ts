export enum EConfigType {
  VMESS = 1,
  CUSTOM = 2,
  SHADOWSOCKS = 3,
  SOCKS = 4,
  VLESS = 5,
  TROJAN = 6,
  WIREGUARD = 7,
  HYSTERIA2 = 9,
  HYSTERIA = 900,
  HTTP = 10,
  POLICYGROUP = 101,
  PROXYCHAIN = 102,
}

export function configTypeFromInt(value: number): EConfigType {
  for (const t of Object.values(EConfigType)) {
    if (typeof t === 'number' && t === value) return t as EConfigType;
  }
  return EConfigType.VMESS;
}

export enum NetworkType {
  TCP = 'tcp',
  KCP = 'kcp',
  WS = 'ws',
  HTTP_UPGRADE = 'httpupgrade',
  XHTTP = 'xhttp',
  HTTP = 'http',
  H2 = 'h2',
  GRPC = 'grpc',
  HYSTERIA = 'hysteria',
}

export enum RoutingType {
  IP_IF_NON_MATCH = 'ipIfNonMatch',
  IP_ONLY = 'ipOnly',
  DOMAIN_ONLY = 'domainOnly',
}

export enum BalancerStrategyType {
  LEAST_PING = 'leastPing',
  ROUND_ROBIN = 'roundRobin',
  RANDOM = 'random',
  LEAST_LOAD = 'leastLoad',
}

export enum Language {
  ZH = 'zh',
  ZH_CN = 'zh-CN',
  ZH_TW = 'zh-TW',
  EN = 'en',
  RU = 'ru',
  TR = 'tr',
  FA = 'fa',
}

export enum VpnInterfaceAddressConfig {
  CONFIG_A = 'A',
  CONFIG_B = 'B',
  CONFIG_C = 'C',
}
