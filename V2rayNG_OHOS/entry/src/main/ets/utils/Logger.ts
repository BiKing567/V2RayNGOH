import hilog from '@ohos.hilog';

const DOMAIN = 0xFADE;
const TAG = 'V2RayNG';

const MAX_BUFFER = 500;

export enum LogLevel {
  DEBUG = 3,
  INFO = 4,
  WARN = 5,
  ERROR = 6,
}

const LOG_LEVEL_PREFIX: Record<number, string> = {
  [LogLevel.DEBUG]: 'D',
  [LogLevel.INFO]: 'I',
  [LogLevel.WARN]: 'W',
  [LogLevel.ERROR]: 'E',
};

let currentLogLevel: LogLevel = LogLevel.DEBUG;
const logBuffer: string[] = [];

export function setLogLevel(level: LogLevel): void {
  currentLogLevel = level;
}

export function getLogBuffer(): string[] {
  return logBuffer;
}

function bufferLog(level: LogLevel, message: string): void {
  const prefix = LOG_LEVEL_PREFIX[level];
  logBuffer.push(`[${prefix}] [${TAG}] ${message}`);
  if (logBuffer.length > MAX_BUFFER) {
    logBuffer.splice(0, logBuffer.length - MAX_BUFFER);
  }
}

function log(level: LogLevel, message: string): void {
  if (level < currentLogLevel) return;
  bufferLog(level, message);
  try {
    switch (level) {
      case LogLevel.DEBUG:
        hilog.debug(DOMAIN, TAG, '%{public}s', message);
        break;
      case LogLevel.INFO:
        hilog.info(DOMAIN, TAG, '%{public}s', message);
        break;
      case LogLevel.WARN:
        hilog.warn(DOMAIN, TAG, '%{public}s', message);
        break;
      case LogLevel.ERROR:
        hilog.error(DOMAIN, TAG, '%{public}s', message);
        break;
    }
  } catch (_) {}
}

export function d(message: string): void {
  log(LogLevel.DEBUG, message);
}

export function i(message: string): void {
  log(LogLevel.INFO, message);
}

export function w(message: string): void {
  log(LogLevel.WARN, message);
}

export function e(message: string): void {
  log(LogLevel.ERROR, message);
}
