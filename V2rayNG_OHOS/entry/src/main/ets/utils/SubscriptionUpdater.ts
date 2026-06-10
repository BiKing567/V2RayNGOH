import http from '@ohos.net.http';
import util from '@ohos.util';
import { ProfileItem } from '../model/ProfileItem';
import { EConfigType } from '../model/Enums';
import { SubscriptionItem } from '../model/SubscriptionItem';
import * as Logger from './Logger';
import * as Storage from './Storage';

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error('Request timed out after ' + ms + 'ms')), ms)
    )
  ]);
}

export async function fetchSubscription(sub: SubscriptionItem): Promise<ProfileItem[]> {
  const httpReq = http.createHttp();
  try {
    const result = await withTimeout(httpReq.request(sub.url, {
      method: http.RequestMethod.GET,
      connectTimeout: 15000,
      readTimeout: 30000,
      header: { 'User-Agent': 'V2RayNG' },
      expectDataType: 0,
    }), 20000);

    const raw = result.result;
    let body = (typeof raw === 'string') ? raw : String(raw);
    Logger.i('Subscription response code=' + result.responseCode + ' bodyLen=' + body.length + ' body.prefix=' + body.substring(0, 120));

    if (result.responseCode !== 200) {
      Logger.e('Subscription fetch failed: ' + result.responseCode);
      return [];
    }

    // Trim and try to decode as base64
    body = body.trim();
    const decoded = decodeBase64(body);
    Logger.i('Decoded body len=' + decoded.length + ' prefix=' + decoded.substring(0, 120));

    // Parse lines
    const profiles: ProfileItem[] = [];
    const lines = decoded.split('\n');
    Logger.i('Lines count=' + lines.length);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      const profile = parseShareLink(trimmed);
      if (profile) {
        profile.subscriptionId = sub.id;
        profiles.push(profile);
      } else {
        Logger.i('Unparseable line: ' + trimmed.substring(0, 60));
      }
    }

    return profiles;
  } catch (err) {
    Logger.e('Subscription fetch error: ' + JSON.stringify(err));
    return [];
  } finally {
    httpReq.destroy();
  }
}

function uint8ToString(arr: Uint8Array): string {
  let result = '';
  for (let i = 0; i < arr.length; i++) {
    result += String.fromCharCode(arr[i]);
  }
  return result;
}

function decodeBase64(str: string): string {
  try {
    const decoder = new util.Base64();
    const mod = str.length % 4;
    const padded = mod === 0 ? str : str + '===='.substring(0, 4 - mod);
    const decoded = decoder.decodeSync(padded);
    return uint8ToString(decoded);
  } catch (err) {
    Logger.d('Base64 decode failed, trying raw: ' + err);
    return str;
  }
}

export function parseShareLink(link: string): ProfileItem | null {
  try {
    if (link.startsWith('vmess://')) {
      return parseVmess(link);
    } else if (link.startsWith('vless://')) {
      return parseVless(link);
    } else if (link.startsWith('ss://')) {
      return parseShadowsocks(link);
    } else if (link.startsWith('trojan://')) {
      return parseTrojan(link);
    } else if (link.startsWith('socks://') || link.startsWith('socks5://')) {
      return parseSocks(link);
    } else if (link.startsWith('hysteria2://') || link.startsWith('hy2://')) {
      return parseHysteria2(link);
    }
  } catch (err) {
    Logger.e('Failed to parse share link: ' + link);
  }
  return null;
}

function parseVmess(link: string): ProfileItem {
  const profile = new ProfileItem(EConfigType.VMESS);
  const b64 = link.replace('vmess://', '');
  try {
    const json = JSON.parse(decodeBase64(b64));
    profile.server = json.add || '';
    profile.serverPort = String(json.port || '443');
    profile.password = json.id || '';
    profile.security = json.scy || 'auto';
    profile.network = json.net || 'tcp';
    profile.host = json.host || '';
    profile.path = json.path || '';
    profile.headerType = json.type || 'none';
    profile.remarks = json.ps || '';
    profile.sni = json.sni || '';
    profile.alpn = json.alpn || '';
    profile.fingerPrint = json.fp || '';
  } catch {
    // fallback: parse as standard VMess link
  }
  return profile;
}

function parseUrlSimple(urlStr: string): { hostname: string; port: string; username: string; password: string; hash: string; query: Map<string, string> } {
  let hostname = '';
  let port = '';
  let username = '';
  let password = '';
  let hash = '';
  const query = new Map<string, string>();
  try {
    const schemeEnd = urlStr.indexOf('://');
    const afterScheme = schemeEnd >= 0 ? urlStr.substring(schemeEnd + 3) : urlStr;
    const hashIdx = afterScheme.indexOf('#');
    const beforeHash = hashIdx >= 0 ? afterScheme.substring(0, hashIdx) : afterScheme;
    hash = hashIdx >= 0 ? '#' + afterScheme.substring(hashIdx + 1) : '';
    const qIdx = beforeHash.indexOf('?');
    const hostPart = qIdx >= 0 ? beforeHash.substring(0, qIdx) : beforeHash;
    if (qIdx >= 0) {
      const qs = beforeHash.substring(qIdx + 1);
      for (const pair of qs.split('&')) {
        const eqIdx = pair.indexOf('=');
        if (eqIdx > 0) {
          query.set(decodeURIComponent(pair.substring(0, eqIdx)), decodeURIComponent(pair.substring(eqIdx + 1)));
        }
      }
    }
    const atIdx = hostPart.lastIndexOf('@');
    if (atIdx >= 0) {
      const userPass = hostPart.substring(0, atIdx);
      const colonIdx = userPass.indexOf(':');
      username = colonIdx >= 0 ? decodeURIComponent(userPass.substring(0, colonIdx)) : decodeURIComponent(userPass);
      password = colonIdx >= 0 ? decodeURIComponent(userPass.substring(colonIdx + 1)) : '';
    }
    const realHost = atIdx >= 0 ? hostPart.substring(atIdx + 1) : hostPart;
    const bracketClose = realHost.lastIndexOf(']');
    const portColon = bracketClose >= 0 ? realHost.indexOf(':', bracketClose) : realHost.lastIndexOf(':');
    if (portColon >= 0) {
      hostname = realHost.substring(0, portColon);
      port = realHost.substring(portColon + 1);
    } else {
      hostname = realHost;
    }
    hostname = decodeURIComponent(hostname);
    hostname = hostname.replace(/^\[|\]$/g, '');
  } catch (_) {}
  return { hostname, port, username, password, hash, query };
}

function parseVless(link: string): ProfileItem {
  const profile = new ProfileItem(EConfigType.VLESS);
  const parsed = parseUrlSimple(link);
  profile.server = parsed.hostname;
  profile.serverPort = parsed.port || '443';
  profile.password = parsed.hash ? '' : (parsed.username || '');
  profile.network = parsed.query.get('type') || 'tcp';
  profile.host = parsed.query.get('host') || '';
  profile.path = parsed.query.get('path') || '';
  profile.security = parsed.query.get('security') || 'none';
  profile.sni = parsed.query.get('sni') || '';
  profile.alpn = parsed.query.get('alpn') || '';
  profile.fingerPrint = parsed.query.get('fp') || '';
  profile.flow = parsed.query.get('flow') || '';
  profile.remarks = decodeURIComponent(parsed.hash.replace('#', '') || '');
  // Extract UUID from userinfo
  if (parsed.username && parsed.username.includes('@')) {
    profile.password = parsed.username.split('@')[0];
  } else {
    profile.password = parsed.username || '';
  }
  return profile;
}

function parseShadowsocks(link: string): ProfileItem {
  const profile = new ProfileItem(EConfigType.SHADOWSOCKS);
  const stripped = link.replace('ss://', '');
  // Try SIP002 format: ss://method:password@host:port#tag
  const hashIdx = stripped.indexOf('#');
  const remarks = hashIdx >= 0 ? decodeURIComponent(stripped.substring(hashIdx + 1)) : '';
  profile.remarks = remarks;

  const main = hashIdx >= 0 ? stripped.substring(0, hashIdx) : stripped;
  const atIdx = main.indexOf('@');
  if (atIdx >= 0) {
    const userInfo = decodeBase64(main.substring(0, atIdx));
    const [method, password] = userInfo.split(':');
    profile.method = method || 'aes-256-gcm';
    profile.password = password || '';

    const hostPort = main.substring(atIdx + 1);
    const colonIdx = hostPort.lastIndexOf(':');
    profile.server = colonIdx >= 0 ? hostPort.substring(0, colonIdx) : hostPort;
    profile.serverPort = colonIdx >= 0 ? hostPort.substring(colonIdx + 1) : '443';
  }
  return profile;
}

function parseTrojan(link: string): ProfileItem {
  const profile = new ProfileItem(EConfigType.TROJAN);
  const parsed = parseUrlSimple(link);
  profile.server = parsed.hostname;
  profile.serverPort = parsed.port || '443';
  profile.password = parsed.username || '';
  profile.sni = parsed.query.get('sni') || '';
  profile.flow = parsed.query.get('flow') || '';
  profile.fingerPrint = parsed.query.get('fp') || '';
  profile.remarks = decodeURIComponent(parsed.hash.replace('#', '') || '');
  return profile;
}

function parseSocks(link: string): ProfileItem {
  const profile = new ProfileItem(EConfigType.SOCKS);
  const parsed = parseUrlSimple(link);
  profile.server = parsed.hostname;
  profile.serverPort = parsed.port || '1080';
  profile.username = parsed.username || '';
  profile.password = parsed.password || '';
  profile.remarks = decodeURIComponent(parsed.hash.replace('#', '') || '');
  return profile;
}

function parseHysteria2(link: string): ProfileItem {
  const profile = new ProfileItem(EConfigType.HYSTERIA2);
  const parsed = parseUrlSimple(link.replace('hy2://', 'hysteria2://'));
  profile.server = parsed.hostname;
  profile.serverPort = parsed.port || '443';
  profile.password = parsed.username || '';
  profile.sni = parsed.query.get('sni') || '';
  profile.insecure = parsed.query.get('insecure') === '1';
  profile.pinSHA256 = parsed.query.get('pinSHA256') || '';
  profile.bandwidthUp = parsed.query.get('up') || '';
  profile.bandwidthDown = parsed.query.get('down') || '';
  profile.remarks = decodeURIComponent(parsed.hash.replace('#', '') || '');
  return profile;
}
