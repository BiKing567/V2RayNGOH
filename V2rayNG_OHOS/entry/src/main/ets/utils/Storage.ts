import preferences from '@ohos.data.preferences';
import { ProfileItem } from '../model/ProfileItem';
import { SubscriptionItem } from '../model/SubscriptionItem';
import { EConfigType, configTypeFromInt } from '../model/Enums';
import * as Logger from './Logger';

let store: preferences.Preferences | null = null;

const KEYS = {
  SELECTED_SERVER: 'selected_server',
  SERVER_PREFIX: 'server_',
  SUBSCRIPTION_PREFIX: 'sub_',
  SUBSCRIPTION_LIST: 'subscription_list',
  SETTINGS_PREFIX: 'pref_',
};

export async function initStorage(context: Context): Promise<void> {
  store = await preferences.getPreferences(context, 'v2rayng_store');
  Logger.i('Storage initialized');
}

// --- Settings ---
export async function getSetting(key: string): Promise<string | undefined> {
  if (!store) return undefined;
  const val = await store.get(KEYS.SETTINGS_PREFIX + key, '');
  return val !== undefined ? String(val) : undefined;
}

export async function setSetting(key: string, value: string): Promise<void> {
  if (!store) return;
  await store.put(KEYS.SETTINGS_PREFIX + key, value);
  await store.flush();
}

export async function getSettingBool(key: string): Promise<boolean | undefined> {
  const val = await getSetting(key);
  if (val === undefined) return undefined;
  return val === 'true';
}

export async function setSettingBool(key: string, value: boolean): Promise<void> {
  await setSetting(key, value ? 'true' : 'false');
}

export async function getSettingInt(key: string): Promise<number | undefined> {
  const val = await getSetting(key);
  if (val === undefined) return undefined;
  const n = parseInt(val);
  return isNaN(n) ? undefined : n;
}

export async function setSettingInt(key: string, value: number): Promise<void> {
  await setSetting(key, value.toString());
}

// --- Server Profile ---
export async function saveServer(guid: string, profile: ProfileItem): Promise<void> {
  if (!store) return;
  const key = KEYS.SERVER_PREFIX + guid;
  await store.put(key, JSON.stringify(profile.toJSON()));
  await store.flush();
}

export async function loadServer(guid: string): Promise<ProfileItem | undefined> {
  if (!store) return undefined;
  const key = KEYS.SERVER_PREFIX + guid;
  const raw = await store.get(key, '');
  if (!raw) return undefined;
  try {
    const json = JSON.parse(raw as string);
    return ProfileItem.fromJSON(json);
  } catch (err) {
    Logger.e('Failed to parse server config: ' + guid);
    return undefined;
  }
}

export async function deleteServer(guid: string): Promise<void> {
  if (!store) return;
  const key = KEYS.SERVER_PREFIX + guid;
  await store.delete(key);
  await store.flush();
}

export async function getAllServerGuids(): Promise<string[]> {
  if (!store) return [];
  const all = await store.getAll();
  const prefix = KEYS.SERVER_PREFIX;
  const guids: string[] = [];
  for (const key in all) {
    if (key.startsWith(prefix)) {
      guids.push(key.substring(prefix.length));
    }
  }
  return guids;
}

export async function getSelectedServer(): Promise<string | undefined> {
  if (!store) return undefined;
  const val = await store.get(KEYS.SELECTED_SERVER, '');
  return val !== undefined ? String(val) : undefined;
}

export async function setSelectedServer(guid: string): Promise<void> {
  if (!store) return;
  await store.put(KEYS.SELECTED_SERVER, guid);
  await store.flush();
}

// --- Subscription ---
export async function saveSubscriptionList(items: SubscriptionItem[]): Promise<void> {
  if (!store) return;
  await store.put(KEYS.SUBSCRIPTION_LIST, JSON.stringify(items.map(i => i.toJSON())));
  await store.flush();
}

export async function loadSubscriptionList(): Promise<SubscriptionItem[]> {
  if (!store) return [];
  const raw = await store.get(KEYS.SUBSCRIPTION_LIST, '[]');
  try {
    const arr = JSON.parse(raw as string) as Record<string, Object>[];
    return arr.map(j => SubscriptionItem.fromJSON(j));
  } catch {
    return [];
  }
}
