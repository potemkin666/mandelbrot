import { CLOUD_SYNC_KEYS } from './sync-keys';

const RESET_PREFIXES = ['worldmonitor', 'wm-', 'aviation:'];
const RESET_DATABASES = [
  'worldmonitor_db',
  'worldmonitor_persistent_cache',
  'worldmonitor_vector_store',
] as const;

function deleteIndexedDb(name: string): Promise<void> {
  if (typeof indexedDB === 'undefined') return Promise.resolve();
  return new Promise((resolve) => {
    try {
      const request = indexedDB.deleteDatabase(name);
      request.onsuccess = () => resolve();
      request.onerror = () => resolve();
      request.onblocked = () => resolve();
    } catch {
      resolve();
    }
  });
}

export async function resetMandelLocalData(): Promise<void> {
  try {
    const keys = new Set<string>(CLOUD_SYNC_KEYS as readonly string[]);
    for (let index = localStorage.length - 1; index >= 0; index -= 1) {
      const key = localStorage.key(index);
      if (!key) continue;
      if (keys.has(key) || RESET_PREFIXES.some((prefix) => key.startsWith(prefix))) {
        localStorage.removeItem(key);
      }
    }
  } catch {
    // ignore storage issues during reset
  }

  try {
    sessionStorage.clear();
  } catch {
    // ignore storage issues during reset
  }

  if (typeof caches !== 'undefined') {
    try {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
    } catch {
      // ignore cache API failures during reset
    }
  }

  await Promise.all(RESET_DATABASES.map((dbName) => deleteIndexedDb(dbName)));
  window.location.reload();
}
