import { createClient } from '@supabase/supabase-js';

import { SecureSessionStorage } from '@/lib/secureSessionStorage';

jest.mock('@supabase/supabase-js', () => ({ createClient: jest.fn(() => ({})) }));
jest.mock('@/lib/secureSessionStorage', () => ({ SecureSessionStorage: jest.fn() }));

describe('supabase client (mobile)', () => {
  it('connects with the .env settings and stores the session encrypted', () => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = 'https://x.supabase.co';
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'key';

    jest.isolateModules(() => {
      require('@/lib/supabase');
    });

    expect(createClient).toHaveBeenCalledWith(
      'https://x.supabase.co',
      'key',
      expect.objectContaining({
        auth: expect.objectContaining({
          storage: expect.any(SecureSessionStorage),
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: false,
          flowType: 'pkce',
        }),
      }),
    );
  });
});

describe('supabase client (web)', () => {
  it('uses the browser default storage instead of phone secure storage', () => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = 'https://x.supabase.co';
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'key';
    (createClient as jest.Mock).mockClear();
    (SecureSessionStorage as unknown as jest.Mock).mockClear();

    jest.isolateModules(() => {
      require('@/lib/supabase.web');
    });

    const options = (createClient as jest.Mock).mock.calls[0][2];
    expect(options.auth.storage).toBeUndefined();
    expect(options.auth.persistSession).toBe(true);
    expect(options.auth.flowType).toBe('pkce');
    expect(SecureSessionStorage).not.toHaveBeenCalled();
  });
});
