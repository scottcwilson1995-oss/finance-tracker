import { Text } from 'react-native';
import { renderRouter, screen } from 'expo-router/testing-library';

import AppStack from '@/components/AppStack';
import { useAuth } from '@/lib/auth';

jest.mock('@/lib/auth', () => ({ useAuth: jest.fn() }));

const routes = {
  _layout: AppStack,
  'sign-in': () => <Text>sign-in screen</Text>,
  '(tabs)/_layout': () => <Text>tabs</Text>,
  '(tabs)/index': () => <Text>overview screen</Text>,
};

describe('AppStack', () => {
  it('shows only the sign-in screen when signed out', async () => {
    (useAuth as jest.Mock).mockReturnValue({ session: null, loading: false });

    await renderRouter(routes, { initialUrl: '/' });

    expect(screen.getByText('sign-in screen')).toBeTruthy();
    expect(screen.queryByText('overview screen')).toBeNull();
  });

  it('shows the tabs and not the sign-in screen when signed in', async () => {
    (useAuth as jest.Mock).mockReturnValue({ session: { user: { id: 'u1' } }, loading: false });

    await renderRouter(routes, { initialUrl: '/' });

    expect(screen.getByText('tabs')).toBeTruthy();
    expect(screen.queryByText('sign-in screen')).toBeNull();
  });

  it('redirects a signed-out visitor who opens a tab URL directly', async () => {
    (useAuth as jest.Mock).mockReturnValue({ session: null, loading: false });

    await renderRouter(routes, { initialUrl: '/(tabs)' });

    expect(screen.getByText('sign-in screen')).toBeTruthy();
    expect(screen.queryByText('tabs')).toBeNull();
  });

  it('renders nothing while the saved session is still loading', async () => {
    (useAuth as jest.Mock).mockReturnValue({ session: null, loading: true });

    await renderRouter(routes, { initialUrl: '/' });

    expect(screen.queryByText('sign-in screen')).toBeNull();
    expect(screen.queryByText('tabs')).toBeNull();
  });
});
