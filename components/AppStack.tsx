import { Stack } from 'expo-router';

import { useAuth } from '@/lib/auth';

// Signed-out visitors can only reach the sign-in screen; signed-in users get the tabs.
export default function AppStack() {
  const { session, loading } = useAuth();

  if (loading) return null;

  const signedIn = !!session;

  return (
    <Stack>
      <Stack.Protected guard={signedIn}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Protected guard={!signedIn}>
        <Stack.Screen name="sign-in" options={{ headerShown: false }} />
      </Stack.Protected>
    </Stack>
  );
}
