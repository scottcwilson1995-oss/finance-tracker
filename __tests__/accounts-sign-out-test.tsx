import { fireEvent, render, screen } from '@testing-library/react-native';

import AccountsScreen from '@/app/(tabs)/accounts';
import { useAuth } from '@/lib/auth';

jest.mock('@/lib/auth', () => ({ useAuth: jest.fn() }));

describe('Accounts screen', () => {
  it('lets the user sign out', async () => {
    const signOut = jest.fn().mockResolvedValue(undefined);
    (useAuth as jest.Mock).mockReturnValue({ signOut });
    await render(<AccountsScreen />);

    await fireEvent.press(screen.getByRole('button', { name: 'Sign out' }));

    expect(signOut).toHaveBeenCalled();
  });
});
