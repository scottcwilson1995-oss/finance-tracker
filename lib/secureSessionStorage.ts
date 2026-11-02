import 'react-native-get-random-values';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as aesjs from 'aes-js';
import * as SecureStore from 'expo-secure-store';

// The login session is too large for SecureStore (2 KB limit), so it is
// encrypted with AES-256 and saved in AsyncStorage. Only the encryption key
// lives in SecureStore (Android Keystore). Pattern from Supabase's Expo guide.
export class SecureSessionStorage {
  async getItem(key: string) {
    const encrypted = await AsyncStorage.getItem(key);
    if (!encrypted) return encrypted;

    const keyHex = await SecureStore.getItemAsync(key);
    if (!keyHex) return null;

    const cipher = new aesjs.ModeOfOperation.ctr(
      aesjs.utils.hex.toBytes(keyHex),
      new aesjs.Counter(1),
    );
    return aesjs.utils.utf8.fromBytes(cipher.decrypt(aesjs.utils.hex.toBytes(encrypted)));
  }

  async setItem(key: string, value: string) {
    const encryptionKey = crypto.getRandomValues(new Uint8Array(256 / 8));
    const cipher = new aesjs.ModeOfOperation.ctr(encryptionKey, new aesjs.Counter(1));
    const encrypted = cipher.encrypt(aesjs.utils.utf8.toBytes(value));

    await SecureStore.setItemAsync(key, aesjs.utils.hex.fromBytes(encryptionKey));
    await AsyncStorage.setItem(key, aesjs.utils.hex.fromBytes(encrypted));
  }

  async removeItem(key: string) {
    await AsyncStorage.removeItem(key);
    await SecureStore.deleteItemAsync(key);
  }
}
