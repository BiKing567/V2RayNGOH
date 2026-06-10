import { ProfileItem } from '../model/ProfileItem';
import { EConfigType } from '../model/Enums';
import * as Logger from './Logger';

export class ConfigBuilder {
  static buildV2RayConfig(
    profile: ProfileItem,
    socksPort: number,
    configType: 'proxy' | 'vpn',
    context?: Context,
  ): string {
    const config: Record<string, object | string | number | boolean> = {
      log: {
        loglevel: 'warning',
      },
      dns: {
        servers: [
          '1.1.1.1',
          {
            address: '223.5.5.5',
            port: 53,
            domains: ['geosite:cn'],
          },
        ],
      },
      routing: {
        domainStrategy: 'AsIs',
        rules: [
          {
            type: 'field',
            ip: ['geoip:private'],
            outboundTag: 'direct',
          },
          {
            type: 'field',
            domain: ['geosite:cn'],
            outboundTag: 'direct',
          },
        ],
      },
      inbounds: [],
      outbounds: [],
      policy: {
        levels: {
          '0': {
            statsUserUplink: true,
            statsUserDownlink: true,
          },
        },
        system: {
          statsInboundUplink: true,
          statsInboundDownlink: true,
          statsOutboundUplink: true,
          statsOutboundDownlink: true,
        },
      },
      stats: {},
    };

    // Build inbounds using local array
    const inbounds: object[] = [
      {
        listen: '127.0.0.1',
        port: socksPort,
        protocol: 'socks',
        settings: {
          udp: true,
        },
        tag: 'socks-in',
      },
    ];

    if (configType === 'vpn') {
      inbounds.push({
        listen: '127.0.0.1',
        port: socksPort + 1,
        protocol: 'http',
        settings: {},
        tag: 'http-in',
      });
    }

    // Build outbound based on profile type
    const outbound = this.buildOutbound(profile);
    const outbounds: object[] = [outbound];

    // Direct outbound
    outbounds.push({
      protocol: 'freedom',
      tag: 'direct',
    });

    // Block outbound
    outbounds.push({
      protocol: 'blackhole',
      tag: 'block',
    });

    if (configType === 'vpn') {
      inbounds.push({
        tag: 'tun-in',
        protocol: 'tun',
        settings: {
          mtu: 1500,
          udp: true,
        },
      });
    }

    config['inbounds'] = inbounds;
    config['outbounds'] = outbounds;

    return JSON.stringify(config, null, 2);
  }

  private static buildOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    const outbound: Record<string, object | string | number | boolean> = {
      tag: 'proxy',
    };

    switch (profile.configType) {
      case EConfigType.VMESS:
        return this.buildVMessOutbound(profile);

      case EConfigType.VLESS:
        return this.buildVLESSOutbound(profile);

      case EConfigType.SHADOWSOCKS:
        return this.buildShadowsocksOutbound(profile);

      case EConfigType.TROJAN:
        return this.buildTrojanOutbound(profile);

      case EConfigType.SOCKS:
        return this.buildSocksOutbound(profile);

      case EConfigType.HTTP:
        return this.buildHTTPOutbound(profile);

      case EConfigType.WIREGUARD:
        return this.buildWireGuardOutbound(profile);

      case EConfigType.HYSTERIA2:
        return this.buildHysteria2Outbound(profile);

      case EConfigType.CUSTOM:
        // For custom, the profile IS the config
        try {
          return JSON.parse(profile.server || '{}');
        } catch {
          return outbound;
        }

      default:
        return this.buildVMessOutbound(profile);
    }
  }

  private static buildVMessOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    const outbound: Record<string, object | string | number | boolean> = {
      tag: 'proxy',
      protocol: 'vmess',
      settings: {
        vnext: [
          {
            address: profile.server || '',
            port: parseInt(profile.serverPort || '443'),
            users: [
              {
                id: profile.password || '',
                security: profile.security || 'auto',
                level: 8,
              },
            ],
          },
        ],
      },
      streamSettings: this.buildStreamSettings(profile),
      mux: this.buildMuxConfig(),
    };
    return outbound;
  }

  private static buildVLESSOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    const outbound: Record<string, object | string | number | boolean> = {
      tag: 'proxy',
      protocol: 'vless',
      settings: {
        vnext: [
          {
            address: profile.server || '',
            port: parseInt(profile.serverPort || '443'),
            users: [
              {
                id: profile.password || '',
                flow: profile.flow || '',
                encryption: 'none',
                level: 8,
              },
            ],
          },
        ],
      },
      streamSettings: this.buildStreamSettings(profile),
    };
    return outbound;
  }

  private static buildShadowsocksOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    return {
      tag: 'proxy',
      protocol: 'shadowsocks',
      settings: {
        servers: [
          {
            address: profile.server || '',
            port: parseInt(profile.serverPort || '443'),
            method: profile.method || 'aes-256-gcm',
            password: profile.password || '',
            ivCheck: false,
          },
        ],
      },
    };
  }

  private static buildTrojanOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    const outbound: Record<string, object | string | number | boolean> = {
      tag: 'proxy',
      protocol: 'trojan',
      settings: {
        servers: [
          {
            address: profile.server || '',
            port: parseInt(profile.serverPort || '443'),
            password: profile.password || '',
            flow: profile.flow || '',
          },
        ],
      },
      streamSettings: {
        network: 'tcp',
        security: 'tls',
        tlsSettings: {
          serverName: profile.sni || profile.server || '',
          allowInsecure: profile.insecure || false,
          fingerprint: profile.fingerPrint || '',
        },
      },
    };
    return outbound;
  }

  private static buildSocksOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    return {
      tag: 'proxy',
      protocol: 'socks',
      settings: {
        servers: [
          {
            address: profile.server || '',
            port: parseInt(profile.serverPort || '1080'),
            users: profile.username ? [
              {
                user: profile.username,
                pass: profile.password || '',
              },
            ] : [],
          },
        ],
      },
    };
  }

  private static buildHTTPOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    return {
      tag: 'proxy',
      protocol: 'http',
      settings: {
        servers: [
          {
            address: profile.server || '',
            port: parseInt(profile.serverPort || '80'),
            users: profile.username ? [
              {
                user: profile.username,
                pass: profile.password || '',
              },
            ] : [],
          },
        ],
      },
    };
  }

  private static buildWireGuardOutbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    return {
      tag: 'proxy',
      protocol: 'wireguard',
      settings: {
        secretKey: profile.secretKey || '',
        address: [
          profile.localAddress || '172.16.0.2/32',
        ],
        peers: [
          {
            endpoint: `${profile.server || ''}:${profile.serverPort || '51820'}`,
            publicKey: profile.publicKey || '',
            preSharedKey: profile.preSharedKey || '',
            allowedIPs: ['0.0.0.0/0', '::/0'],
          },
        ],
        mtu: profile.mtu || 1420,
        kernelMode: false,
      },
    };
  }

  private static buildHysteria2Outbound(profile: ProfileItem): Record<string, object | string | number | boolean> {
    return {
      tag: 'proxy',
      protocol: 'hysteria2',
      settings: {
        server: `${profile.server || ''}:${profile.serverPort || '443'}`,
        password: profile.password || '',
        congestion: {
          type: 'bbr',
        },
        tls: {
          sni: profile.sni || profile.server || '',
          insecure: profile.insecure || false,
          pinSHA256: profile.pinSHA256 || '',
        },
        bandwidth: {
          up: profile.bandwidthUp || '50 mbps',
          down: profile.bandwidthDown || '150 mbps',
        },
      },
    };
  }

  private static buildStreamSettings(profile: ProfileItem): Record<string, object | string | number | boolean> {
    const network = profile.network || 'tcp';
    const streamSettings: Record<string, object | string | number | boolean> = {
      network: network,
      security: profile.security || 'none',
    };

    if (profile.security === 'tls' || profile.security === 'reality') {
      streamSettings['tlsSettings'] = {
        serverName: profile.sni || profile.server || '',
        alpn: profile.alpn ? profile.alpn.split(',') : [],
        allowInsecure: profile.insecure || false,
        fingerprint: profile.fingerPrint || '',
      };
    }

    if (profile.security === 'reality') {
      streamSettings['realitySettings'] = {
        serverName: profile.sni || profile.server || '',
        fingerprint: profile.fingerPrint || 'chrome',
        publicKey: profile.publicKey || '',
        shortId: profile.shortId || '',
        spiderX: profile.spiderX || '',
      };
    }

    // WebSocket
    if (network === 'ws') {
      const wsSettings: Record<string, object | string | number | boolean> = {};
      if (profile.path) wsSettings['path'] = profile.path;
      if (profile.host) wsSettings['headers'] = { Host: profile.host };
      streamSettings['wsSettings'] = wsSettings;
    }

    // gRPC
    if (network === 'grpc') {
      streamSettings['grpcSettings'] = {
        serviceName: profile.serviceName || '',
        multiMode: profile.mode === 'multi',
      };
    }

    // KCP
    if (network === 'kcp') {
      streamSettings['kcpSettings'] = {
        mtu: profile.kcpMtu || 1350,
        tti: profile.kcpTti || 20,
        header: { type: profile.headerType || 'none' },
        seed: profile.seed || '',
      };
    }

    // HTTP/2
    if (network === 'h2') {
      streamSettings['httpSettings'] = {
        path: profile.path ? [profile.path] : [],
        host: profile.host ? [profile.host] : [],
      };
    }

    return streamSettings;
  }

  private static buildMuxConfig(): Record<string, object | string | number | boolean> {
    return {
      enabled: true,
      concurrency: 8,
    };
  }
}
