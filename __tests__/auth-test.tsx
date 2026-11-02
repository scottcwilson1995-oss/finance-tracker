import { act, renderHook } from '@testing-library/react-native';
import type { ReactNode } from 'react';

import { AuthProvider, useAuth } from '@/lib/auth';
import { supabase } from '@/lib/supabase';

jest.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: jest.fn(),
      onAuthStateChange: jest.fn(),
      signInWithPassword: jest.fn(),
      signUp: jest.fn(),
      signOut: jest.fn(),
    },
  },
}));

const auth = supabase.auth as unknown as {
  getSession: jest.Mock;
  onAuthStateChange: jest.Mock;
  signInWithPassword: jest.Mock;
  signUp: jest.Mock;
  signOut: jest.Mock;
};

const wrapper = ({ children }: { children: ReactNode }) => <AuthProvider>{children}</AuthProvider>;

beforeEach(() => {
  jest.resetAllMocks();
  auth.onAuthStateChange.mockReturnValue({ data: { subscription: { unsubscribe: jest.fn() } } });
});

describe('AuthProvider', () => {
  it('starts loading, then exposes the saved session', async () => {
    const session = { user: { id: 'u1' } };
    let resolveSession!: (value: unknown) => void;
    auth.getSession.mockReturnValue(new Promise((resolve) => (resolveSession = resolve)));

    const { result } = await renderHook(() => useAuth(), { wrapper });

    expect(result.current.loading).toBe(true);
    expect(result.current.session).toBeNull();

    await act(async () => resolveSession({ data: { session } }));

    expect(result.current.loading).toBe(false);
    expect(result.current.session).toBe(session);
  });

  it('follows sign-in and sign-out events and unsubscribes on unmount', async () => {
    const unsubscribe = jest.fn();
    let listener!: (event: string, session: unknown) => void;
    auth.onAuthStateChange.mockImplementation((cb) => {
      listener = cb;
      return { data: { subscription: { unsubscribe } } };
    });
    auth.getSession.mockResolvedValue({ data: { session: null } });

    const { result, unmount } = await renderHook(() => useAuth(), { wrapper });
    expect(result.current.session).toBeNull();

    const session = { user: { id: 'u1' } };
    await act(async () => listener('SIGNED_IN', session));
    expect(result.current.session).toBe(session);

    await act(async () => listener('SIGNED_OUT', null));
    expect(result.current.session).toBeNull();

    await unmount();
    expect(unsubscribe).toHaveBeenCalled();
  });

  describe('signIn', () => {
    beforeEach(() => auth.getSession.mockResolvedValue({ data: { session: null } }));

    it('signs in with email and password', async () => {
      auth.signInWithPassword.mockResolvedValue({ error: null });
      const { result } = await renderHook(() => useAuth(), { wrapper });

      let outcome;
      await act(async () => {
        outcome = await result.current.signIn('me@example.com', 'hunter22');
      });

      expect(auth.signInWithPassword).toHaveBeenCalledWith({
        email: 'me@example.com',
        password: 'hunter22',
      });
      expect(outcome).toEqual({ error: null });
    });

    it('returns the error message when sign-in fails', async () => {
      auth.signInWithPassword.mockResolvedValue({
        error: { message: 'Invalid login credentials' },
      });
      const { result } = await renderHook(() => useAuth(), { wrapper });

      let outcome;
      await act(async () => {
        outcome = await result.current.signIn('me@example.com', 'wrong');
      });

      expect(outcome).toEqual({ error: 'Invalid login credentials' });
    });
  });

  describe('signUp', () => {
    beforeEach(() => auth.getSession.mockResolvedValue({ data: { session: null } }));

    it('creates an account and reports when email confirmation is needed', async () => {
      auth.signUp.mockResolvedValue({ data: { session: null }, error: null });
      const { result } = await renderHook(() => useAuth(), { wrapper });

      let outcome;
      await act(async () => {
        outcome = await result.current.signUp('new@example.com', 'hunter22');
      });

      expect(auth.signUp).toHaveBeenCalledWith({ email: 'new@example.com', password: 'hunter22' });
      expect(outcome).toEqual({ error: null, needsConfirmation: true });
    });

    it('reports no confirmation needed when signed in right away', async () => {
      auth.signUp.mockResolvedValue({ data: { session: { user: { id: 'u1' } } }, error: null });
      const { result } = await renderHook(() => useAuth(), { wrapper });

      let outcome;
      await act(async () => {
        outcome = await result.current.signUp('new@example.com', 'hunter22');
      });

      expect(outcome).toEqual({ error: null, needsConfirmation: false });
    });

    it('returns the error message when sign-up fails', async () => {
      auth.signUp.mockResolvedValue({
        data: { session: null },
        error: { message: 'User already registered' },
      });
      const { result } = await renderHook(() => useAuth(), { wrapper });

      let outcome;
      await act(async () => {
        outcome = await result.current.signUp('new@example.com', 'hunter22');
      });

      expect(outcome).toEqual({ error: 'User already registered', needsConfirmation: false });
    });
  });

  describe('signOut', () => {
    it('signs out of Supabase', async () => {
      auth.getSession.mockResolvedValue({ data: { session: { user: { id: 'u1' } } } });
      auth.signOut.mockResolvedValue({ error: null });
      const { result } = await renderHook(() => useAuth(), { wrapper });

      await act(async () => {
        await result.current.signOut();
      });

      expect(auth.signOut).toHaveBeenCalled();
    });
  });
});
