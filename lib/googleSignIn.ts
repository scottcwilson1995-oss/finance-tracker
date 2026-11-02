import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';

import { supabase } from '@/lib/supabase';

export type GoogleSignInResult = { error: string | null };

// Phone: open Google in the system browser, then trade the returned code for a session.
export async function signInWithGoogle(): Promise<GoogleSignInResult> {
  const redirectTo = Linking.createURL('auth-callback');

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo, skipBrowserRedirect: true },
  });
  if (error || !data.url) return { error: error?.message ?? 'Could not start Google sign-in.' };

  const result = await WebBrowser.openAuthSessionAsync(data.url, redirectTo);
  if (result.type !== 'success') return { error: null };

  const params = new URL(result.url).searchParams;
  const code = params.get('code');
  if (!code) {
    return {
      error:
        params.get('error_description') ??
        params.get('error') ??
        'Google sign-in did not return a code.',
    };
  }

  const exchange = await supabase.auth.exchangeCodeForSession(code);
  return { error: exchange.error?.message ?? null };
}
