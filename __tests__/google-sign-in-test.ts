import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';

import { signInWithGoogle } from '@/lib/googleSignIn';
import { supabase } from '@/lib/supabase';

jest.mock('@/lib/supabase', () => ({
  supabase: { auth: { signInWithOAuth: jest.fn(), exchangeCodeForSession: jest.fn() } },
}));
jest.mock('expo-web-browser', () => ({ openAuthSessionAsync: jest.fn() }));
jest.mock('expo-linking', () => ({ createURL: jest.fn() }));

const auth = supabase.auth as unknown as {
  signInWithOAuth: jest.Mock;
  exchangeCodeForSession: jest.Mock;
};
const openAuthSession = WebBrowser.openAuthSessionAsync as jest.Mock;
const createURL = Linking.createURL as jest.Mock;

const REDIRECT = 'financetracker://auth-callback';

beforeEach(() => {
  jest.resetAllMocks();
  createURL.mockReturnValue(REDIRECT);
});

describe('signInWithGoogle (phone)', () => {
  it('opens Google in the browser and turns the returned code into a session', async () => {
    auth.signInWithOAuth.mockResolvedValue({
      data: { url: 'https://accounts.google.com/auth' },
      error: null,
    });
    openAuthSession.mockResolvedValue({ type: 'success', url: `${REDIRECT}?code=abc123` });
    auth.exchangeCodeForSession.mockResolvedValue({ error: null });

    const outcome = await signInWithGoogle();

    expect(auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: { redirectTo: REDIRECT, skipBrowserRedirect: true },
    });
    expect(openAuthSession).toHaveBeenCalledWith('https://accounts.google.com/auth', REDIRECT);
    expect(auth.exchangeCodeForSession).toHaveBeenCalledWith('abc123');
    expect(outcome).toEqual({ error: null });
  });

  it('reports the error when the browser comes back with one instead of a code', async () => {
    auth.signInWithOAuth.mockResolvedValue({
      data: { url: 'https://accounts.google.com/auth' },
      error: null,
    });
    openAuthSession.mockResolvedValue({
      type: 'success',
      url: `${REDIRECT}?error=access_denied&error_description=Access+blocked%3A+not+a+test+user`,
    });

    const outcome = await signInWithGoogle();

    expect(outcome).toEqual({ error: 'Access blocked: not a test user' });
    expect(auth.exchangeCodeForSession).not.toHaveBeenCalled();
  });

  it('is not an error when the user closes the browser', async () => {
    auth.signInWithOAuth.mockResolvedValue({
      data: { url: 'https://accounts.google.com/auth' },
      error: null,
    });
    openAuthSession.mockResolvedValue({ type: 'cancel' });

    const outcome = await signInWithGoogle();

    expect(outcome).toEqual({ error: null });
    expect(auth.exchangeCodeForSession).not.toHaveBeenCalled();
  });

  it('reports a failure to start sign-in', async () => {
    auth.signInWithOAuth.mockResolvedValue({
      data: { url: null },
      error: { message: 'Provider is not enabled' },
    });

    const outcome = await signInWithGoogle();

    expect(outcome).toEqual({ error: 'Provider is not enabled' });
    expect(openAuthSession).not.toHaveBeenCalled();
  });

  it('reports a failure to finish sign-in', async () => {
    auth.signInWithOAuth.mockResolvedValue({
      data: { url: 'https://accounts.google.com/auth' },
      error: null,
    });
    openAuthSession.mockResolvedValue({ type: 'success', url: `${REDIRECT}?code=bad` });
    auth.exchangeCodeForSession.mockResolvedValue({ error: { message: 'invalid_client' } });

    expect(await signInWithGoogle()).toEqual({ error: 'invalid_client' });
  });
});
