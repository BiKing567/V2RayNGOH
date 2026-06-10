import * as Logger from './Logger';

export function isValidUrl(str?: string): boolean {
  if (!str) return false;
  try {
    const url = new URL(str);
    return url.protocol === 'http:' || url.protocol === 'https:' || url.protocol === 'socks5:' || url.protocol === 'socks4:';
  } catch {
    return false;
  }
}

export function isPureIpAddress(str?: string): boolean {
  if (!str) return false;
  const ipv4 = /^(\d{1,3}\.){3}\d{1,3}$/;
  const ipv6 = /^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$/;
  if (ipv4.test(str)) {
    return str.split('.').every(octet => parseInt(octet) <= 255);
  }
  return ipv6.test(str);
}

export function getIpv6Address(addr?: string): string {
  if (!addr) return '';
  if (addr.includes(':')) {
    return `[${addr}]`;
  }
  return addr;
}

export function findRandomFreePort(): number {
  return 10000 + Math.floor(Math.random() * 50000);
}

export function base64Deccode(str: string): string {
  try {
    const decoder = util.Base64Helper;
    return decoder.decodeToString(str);
  } catch {
    return '';
  }
}

export function base64DecodeSafe(str: string): string {
  try {
    // standard base64
    const decoder = new util.Base64();
    return decoder.decodeToString(str);
  } catch {
    try {
      // url-safe base64
      const decoder = new util.Base64();
      decoder.decodeToString(str.replace(/-/g, '+').replace(/_/g, '/'));
    } catch {
      return str;
    }
  }
  return str;
}

export function toHexString(bytes: Uint8Array): string {
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

export function parseVmessLink(link: string): Record<string, object | string | number | boolean> | null {
  try {
    const b64 = link.replace('vmess://', '');
    const decoded = base64DecodeSafe(b64);
    return JSON.parse(decoded);
  } catch {
    return null;
  }
}

export function copyToClipboard(text: string): void {
  // Use clipboard API
  try {
    import('@ohos.pasteboard').then(pb => {
      const data = pb.createData(pb.MIMETYPE_TEXT_PLAIN, text);
      pb.getSystemPasteboard().setData(data);
    });
  } catch (e) {
    Logger.e('Clipboard copy failed');
  }
}

export function getDeviceId(): string {
  // Use device UUID
  try {
    import('@ohos.deviceInfo').then(di => {
      return di.uuid;
    });
  } catch {
    return 'unknown-device';
  }
  return 'unknown-device';
}

export function userAssetPath(context: Context): string {
  return context.filesDir + '/assets/';
}
