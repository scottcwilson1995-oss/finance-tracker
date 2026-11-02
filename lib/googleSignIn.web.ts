import { supabase } from '@/lib/supabase';

import type { GoogleSignInResult } from '@/lib/googleSignIn';

// Web: redirect the whole page to Google and back. The Supabase client finishes the
// sign-in when the page loads again with the code in the URL.
export async function signInWithGoogle(): Promise<GoogleSignInResult> {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin },
  });
  return { error: error?.message ?? null };
}
