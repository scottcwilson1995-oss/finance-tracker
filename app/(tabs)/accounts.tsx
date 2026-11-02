import { Pressable, StyleSheet } from 'react-native';

import PlaceholderScreen from '@/components/PlaceholderScreen';
import { Text, View } from '@/components/Themed';
import { useAuth } from '@/lib/auth';

export default function AccountsScreen() {
  const { signOut } = useAuth();

  return (
    <View style={styles.container}>
      <PlaceholderScreen title="Accounts" />
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Sign out"
        style={styles.button}
        onPress={() => signOut()}
      >
        <Text style={styles.buttonText}>Sign out</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  button: {
    margin: 24,
    padding: 14,
    borderRadius: 8,
    alignItems: 'center',
    backgroundColor: '#dc2626',
  },
  buttonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
});
