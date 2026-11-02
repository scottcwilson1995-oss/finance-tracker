import { signInWithGoogle } from '@/lib/googleSignIn.web';
import { supabase } from '@/lib/supabase';

jest.mock('@/lib/supabase', () => ({ supabase: { auth: { signInWithOAuth: jest.fn() } } }));

const signInWithOAuth = (supabase.auth as unknown as { signInWithOAuth: jest.Mock })
  .signInWithOAuth;

beforeEach(() => {
  jest.resetAllMocks();
  Object.defineProperty(globalThis, 'window', {
    value: { location: { origin: 'http://localhost:8081' } },
    configurable: true,
  });
});

describe('signInWithGoogle (web)', () => {
  it('sends the whole page to Google and back to this site', async () => {
    signInWithOAuth.mockResolvedValue({ data: {}, error: null });

    const outcome = await signInWithGoogle();

    expect(signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: { redirectTo: 'http://localhost:8081' },
    });
    expect(outcome).toEqual({ error: null });
  });

  it('reports a failure to start sign-in', async () => {
    signInWithOAuth.mockResolvedValue({ data: {}, error: { message: 'Provider is not enabled' } });

    expect(await signInWithGoogle()).toEqual({ error: 'Provider is not enabled' });
  });
});
