import { getSupabaseConfig } from '@/lib/supabaseConfig';

describe('getSupabaseConfig', () => {
  it('throws a clear error when the Supabase URL is missing', () => {
    expect(() => getSupabaseConfig({ EXPO_PUBLIC_SUPABASE_ANON_KEY: 'key' })).toThrow(
      'EXPO_PUBLIC_SUPABASE_URL is missing. Add it to your .env file.',
    );
  });

  it('throws a clear error when the Supabase key is missing', () => {
    expect(() => getSupabaseConfig({ EXPO_PUBLIC_SUPABASE_URL: 'https://x.supabase.co' })).toThrow(
      'EXPO_PUBLIC_SUPABASE_ANON_KEY is missing. Add it to your .env file.',
    );
  });

  it('returns the URL and key when both are set', () => {
    expect(
      getSupabaseConfig({
        EXPO_PUBLIC_SUPABASE_URL: 'https://x.supabase.co',
        EXPO_PUBLIC_SUPABASE_ANON_KEY: 'key',
      }),
    ).toEqual({ url: 'https://x.supabase.co', key: 'key' });
  });
});
