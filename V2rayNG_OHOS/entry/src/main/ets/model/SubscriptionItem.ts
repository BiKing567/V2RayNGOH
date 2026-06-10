export class SubscriptionItem {
  id: string = '';
  url: string = '';
  remarks: string = '';
  enabled: boolean = true;
  autoUpdate: boolean = false;
  updateInterval: number = 24;
  lastUpdateTime: number = 0;

  toJSON(): Record<string, Object> {
    const result: Record<string, Object> = {};
    const self: Record<string, Object> = this as unknown as Record<string, Object>;
    for (const key of Object.keys(this)) {
      result[key] = self[key];
    }
    return result;
  }

  static fromJSON(json: Record<string, Object>): SubscriptionItem {
    const item = new SubscriptionItem();
    Object.assign(item, json);
    return item;
  }
}
