export interface V2rayConfig {
  log: LogConfig;
  dns: DNSConfig;
  routing: RoutingConfig;
  inbounds: InboundConfig[];
  outbounds: OutboundConfig[];
  policy: PolicyConfig;
  stats: StatsConfig;
  observatory?: ObservatoryConfig;
}

export interface LogConfig {
  access?: string;
  error?: string;
  loglevel?: string;
}

export interface DNSConfig {
  servers: (string | DNSServer)[];
  hosts?: Record<string, string>;
  clientIp?: string;
  tag?: string;
}

export interface DNSServer {
  address: string;
  port?: number;
  domains?: string[];
  expectIPs?: string[];
  skipFallback?: boolean;
}

export interface RoutingConfig {
  domainStrategy?: string;
  rules: RoutingRule[];
  balancers?: BalancerConfig[];
}

export interface RoutingRule {
  type: string;
  domain?: string[];
  ip?: string[];
  port?: string;
  sourcePort?: string;
  network?: string;
  source?: string[];
  user?: string[];
  inboundTag?: string[];
  protocol?: string[];
  attrs?: string;
  outboundTag?: string;
  balancerTag?: string;
  ruleTag?: string;
}

export interface BalancerConfig {
  tag: string;
  selector: string[];
  strategy: BalancerStrategy;
}

export interface BalancerStrategy {
  type: string;
}

export interface InboundConfig {
  listen?: string;
  port: number;
  protocol: string;
  settings: Record<string, object>;
  tag?: string;
  sniffing?: SniffingConfig;
}

export interface SniffingConfig {
  enabled: boolean;
  destOverride: string[];
  metadataOnly?: boolean;
}

export interface OutboundConfig {
  tag: string;
  protocol: string;
  settings: Record<string, object>;
  streamSettings?: StreamSettings;
  mux?: MuxConfig;
  fragment?: FragmentConfig;
  proxySettings?: ProxySettings;
}

export interface StreamSettings {
  network?: string;
  security?: string;
  tlsSettings?: TLSSettings;
  realitySettings?: RealitySettings;
  tcpSettings?: TCPConfig;
  kcpSettings?: KCPConfig;
  wsSettings?: WSConfig;
  httpSettings?: HTTPConfig;
  grpcSettings?: GRPCConfig;
  httpupgradeSettings?: HTTPUpgradeConfig;
  xhttpSettings?: XHTTPConfig;
  sockopt?: SockoptConfig;
}

export interface TLSSettings {
  serverName?: string;
  alpn?: string[];
  allowInsecure?: boolean;
  fingerprint?: string;
  pinSHA256?: string;
  echConfigList?: string;
}

export interface RealitySettings {
  serverName?: string;
  fingerprint?: string;
  publicKey?: string;
  shortId?: string;
  spiderX?: string;
}

export interface MuxConfig {
  enabled: boolean;
  concurrency?: number;
  xudpConcurrency?: number;
  xudpProxyUDP443?: string;
}

export interface FragmentConfig {
  packets?: string;
  length?: string;
  interval?: string;
}

export interface ProxySettings {
  tag: string;
  transportLayer?: boolean;
}

export interface SockoptConfig {
  dialerProxy?: string;
  tcpFastOpen?: boolean;
  tproxy?: string;
  mark?: number;
}

export interface TCPConfig {
  header?: TCPHeader;
}

export interface TCPHeader {
  type: string;
  request?: TCPHeaderConfig;
  response?: TCPHeaderConfig;
}

export interface TCPHeaderConfig {
  version?: number;
  method?: string;
  path?: string[];
  headers?: Record<string, string[]>;
}

export interface KCPConfig {
  mtu?: number;
  tti?: number;
  uplinkCapacity?: number;
  downlinkCapacity?: number;
  congestion?: boolean;
  readBufferSize?: number;
  writeBufferSize?: number;
  header?: KCPHeader;
  seed?: string;
}

export interface KCPHeader {
  type: string;
}

export interface WSConfig {
  path?: string;
  headers?: Record<string, string>;
  maxEarlyData?: number;
  earlyDataHeaderName?: string;
}

export interface HTTPConfig {
  path?: string[];
  host?: string[];
}

export interface GRPCConfig {
  serviceName?: string;
  multiMode?: boolean;
  idleTimeout?: number;
  healthCheckTimeout?: number;
  permitWithoutStream?: boolean;
  initialWindowsSize?: number;
}

export interface HTTPUpgradeConfig {
  path?: string;
  host?: string;
  headers?: Record<string, string>;
}

export interface XHTTPConfig {
  mode?: string;
  path?: string;
  host?: string;
  extra?: Record<string, object>;
}

export interface PolicyConfig {
  levels?: Record<string, LevelPolicy>;
  system?: SystemPolicy;
}

export interface LevelPolicy {
  handshake?: number;
  connIdle?: number;
  uplinkOnly?: number;
  downlinkOnly?: number;
  statsUserUplink?: boolean;
  statsUserDownlink?: boolean;
  bufferSize?: number;
}

export interface SystemPolicy {
  statsInboundUplink?: boolean;
  statsInboundDownlink?: boolean;
  statsOutboundUplink?: boolean;
  statsOutboundDownlink?: boolean;
}

export interface StatsConfig {}

export interface ObservatoryConfig {
  subjectSelector: string[];
  probeURL: string;
  probeInterval: string;
  enableConcurrency?: boolean;
}
