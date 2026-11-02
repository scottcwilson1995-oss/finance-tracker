type Env = Record<string, string | undefined>;

export function getSupabaseConfig(env: Env) {
  if (!env.EXPO_PUBLIC_SUPABASE_URL) {
    throw new Error('EXPO_PUBLIC_SUPABASE_URL is missing. Add it to your .env file.');
  }
  if (!env.EXPO_PUBLIC_SUPABASE_ANON_KEY) {
    throw new Error('EXPO_PUBLIC_SUPABASE_ANON_KEY is missing. Add it to your .env file.');
  }
  return { url: env.EXPO_PUBLIC_SUPABASE_URL, key: env.EXPO_PUBLIC_SUPABASE_ANON_KEY };
}

// Expo only inlines EXPO_PUBLIC_* values when they are referenced by name like this.
export function supabaseConfigFromEnv() {
  return getSupabaseConfig({
    EXPO_PUBLIC_SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
    EXPO_PUBLIC_SUPABASE_ANON_KEY: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
  });
}
