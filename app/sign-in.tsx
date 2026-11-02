import { useState } from 'react';
import { Pressable, StyleSheet, TextInput } from 'react-native';

import { Text, View } from '@/components/Themed';
import { useAuth } from '@/lib/auth';

export default function SignInScreen() {
  const { signIn, signUp } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState<string | null>(null);

  function missingFields() {
    if (email.trim() && password) return false;
    setMessage('Enter your email and password.');
    return true;
  }

  async function handleSignIn() {
    if (missingFields()) return;
    const { error } = await signIn(email.trim(), password);
    setMessage(error);
  }

  async function handleSignUp() {
    if (missingFields()) return;
    const { error, needsConfirmation } = await signUp(email.trim(), password);
    setMessage(
      error ??
        (needsConfirmation ? 'Check your email to confirm your account, then sign in.' : null),
    );
  }

  return (
    <View style={styles.container}>
      <Text accessibilityRole="header" style={styles.title}>
        Finance Tracker
      </Text>
      <TextInput
        accessibilityLabel="Email"
        autoCapitalize="none"
        autoComplete="email"
        keyboardType="email-address"
        style={styles.input}
        value={email}
        onChangeText={setEmail}
      />
      <TextInput
        accessibilityLabel="Password"
        autoCapitalize="none"
        autoComplete="current-password"
        secureTextEntry
        style={styles.input}
        value={password}
        onChangeText={setPassword}
      />
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Sign in"
        style={styles.button}
        onPress={handleSignIn}
      >
        <Text style={styles.buttonText}>Sign in</Text>
      </Pressable>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Create account"
        style={styles.secondaryButton}
        onPress={handleSignUp}
      >
        <Text style={styles.secondaryButtonText}>Create account</Text>
      </Pressable>
      {message ? (
        <Text accessibilityRole="alert" style={styles.message}>
          {message}
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', padding: 24, gap: 12 },
  title: { fontSize: 24, fontWeight: 'bold', textAlign: 'center', marginBottom: 12 },
  input: {
    borderWidth: 1,
    borderColor: '#9ca3af',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#888',
  },
  message: { textAlign: 'center', color: '#dc2626' },
  button: { backgroundColor: '#2f95dc', borderRadius: 8, padding: 14, alignItems: 'center' },
  secondaryButton: { borderRadius: 8, padding: 14, alignItems: 'center' },
  secondaryButtonText: { color: '#2f95dc', fontWeight: 'bold', fontSize: 16 },
  buttonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
});
