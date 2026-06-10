export const startCore: (configJson: string, tunFd: number) => void;
export const stopCore: () => void;
export const isRunning: () => boolean;
export const getVersion: () => string;
export const measureDelay: (url: string) => number;
export const queryTraffic: () => string;
