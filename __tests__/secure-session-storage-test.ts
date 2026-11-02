import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SecureStore from 'expo-secure-store';

import { SecureSessionStorage } from '@/lib/secureSessionStorage';

jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);

jest.mock('expo-secure-store', () => {
  const store = new Map<string, string>();
  return {
    setItemAsync: jest.fn(async (k: string, v: string) => void store.set(k, v)),
    getItemAsync: jest.fn(async (k: string) => store.get(k) ?? null),
    deleteItemAsync: jest.fn(async (k: string) => void store.delete(k)),
  };
});

jest.mock('react-native-get-random-values', () => ({}));

describe('SecureSessionStorage', () => {
  it('returns the value that was saved', async () => {
    const storage = new SecureSessionStorage();

    await storage.setItem('session', '{"token":"abc"}');

    await expect(storage.getItem('session')).resolves.toBe('{"token":"abc"}');
  });

  it('does not keep the value as readable text in regular storage', async () => {
    const storage = new SecureSessionStorage();

    await storage.setItem('session', '{"token":"abc"}');

    const raw = await AsyncStorage.getItem('session');
    expect(raw).not.toBeNull();
    expect(raw).not.toContain('abc');
  });

  it('removes the saved value and its encryption key', async () => {
    const storage = new SecureSessionStorage();
    await storage.setItem('session', '{"token":"abc"}');

    await storage.removeItem('session');

    await expect(storage.getItem('session')).resolves.toBeNull();
    await expect(SecureStore.getItemAsync('session')).resolves.toBeNull();
  });
});
