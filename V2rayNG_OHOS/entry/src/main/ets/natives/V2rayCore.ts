import hilog from '@ohos.hilog';
import native from '@ohos.native';

const DOMAIN = 0x0000;
const TAG = 'V2RAY_CORE';

interface IV2RayBridge {
  startCore(configJson: string, tunFd: number): void;
  stopCore(): void;
  isRunning(): boolean;
  getVersion(): string;
  measureDelay(url: string): number;
  queryTraffic(): string;
}

// Try multiple loading strategies
function loadBridge(): IV2RayBridge | null {
  // Strategy 1: ES module import syntax (transforms to @app:)
  hilog.info(DOMAIN, TAG, 'Trying strategy 1: ES module import of libv2ray_bridge');

  // Strategy 2: loadNativeModule with filename
  try {
    hilog.info(DOMAIN, TAG, 'Trying strategy 2: loadNativeModule');
    const m = loadNativeModule('libv2ray_bridge.so');
    if (m) {
      hilog.info(DOMAIN, TAG, 'loadNativeModule succeeded');
      return m as IV2RayBridge;
    }
  } catch (e) {
    hilog.info(DOMAIN, TAG, 'loadNativeModule failed: %{public}s', (e as Error).message);
  }

  // Strategy 3: native.requireNapi
  try {
    hilog.info(DOMAIN, TAG, 'Trying strategy 3: native.requireNapi');
    const m = native.requireNapi('v2ray_bridge');
    if (m) {
      hilog.info(DOMAIN, TAG, 'native.requireNapi succeeded');
      return m as IV2RayBridge;
    }
  } catch (e) {
    hilog.info(DOMAIN, TAG, 'native.requireNapi failed: %{public}s', (e as Error).message);
  }

  hilog.error(DOMAIN, TAG, 'All loading strategies failed');
  return null;
}

export function startBridge(): IV2RayBridge | null {
  const bridge = loadBridge();
  if (bridge) {
    hilog.info(DOMAIN, TAG, 'Bridge loaded, version: %{public}s', bridge.getVersion());
  }
  return bridge;
}

const STUB: IV2RayBridge = {
  startCore(_configJson: string, _tunFd: number): void {},
  stopCore(): void {},
  isRunning(): boolean { return false; },
  getVersion(): string { return 'stub-0.0.0'; },
  measureDelay(_url: string): number { return -1; },
  queryTraffic(): string { return ''; },
};

let bridgeImpl: IV2RayBridge = STUB;

export function startCore(configJson: string, tunFd: number): void {
  bridgeImpl.startCore(configJson, tunFd);
}

export function stopCore(): void {
  bridgeImpl.stopCore();
}

export function isRunning(): boolean {
  return bridgeImpl.isRunning();
}

export function getVersion(): string {
  return bridgeImpl.getVersion();
}

export function measureDelay(url: string): number {
  return bridgeImpl.measureDelay(url);
}

export function queryTraffic(): string {
  return bridgeImpl.queryTraffic();
}

// Module-level init
try {
  const loaded = loadBridge();
  if (loaded) {
    bridgeImpl = loaded;
    hilog.info(DOMAIN, TAG, 'Bridge initialized successfully: %{public}s', loaded.getVersion());
  } else {
    hilog.info(DOMAIN, TAG, 'Bridge not available — using STUB');
  }
} catch (e) {
  hilog.error(DOMAIN, TAG, 'Init error: %{public}s', (e as Error).message);
}
