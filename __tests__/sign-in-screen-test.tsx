import { fireEvent, render, screen } from '@testing-library/react-native';

import SignInScreen from '@/app/sign-in';
import { useAuth } from '@/lib/auth';

jest.mock('@/lib/auth', () => ({ useAuth: jest.fn() }));

const signIn = jest.fn();
const signUp = jest.fn();

beforeEach(() => {
  jest.resetAllMocks();
  (useAuth as jest.Mock).mockReturnValue({ signIn, signUp });
});

async function fillForm(email: string, password: string) {
  await fireEvent.changeText(screen.getByLabelText('Email'), email);
  await fireEvent.changeText(screen.getByLabelText('Password'), password);
}

describe('Sign-in screen', () => {
  it('signs in with the typed email and password', async () => {
    signIn.mockResolvedValue({ error: null });
    await render(<SignInScreen />);

    await fillForm('me@example.com', 'hunter22');
    await fireEvent.press(screen.getByRole('button', { name: 'Sign in' }));

    expect(signIn).toHaveBeenCalledWith('me@example.com', 'hunter22');
  });

  it('shows the error when sign-in fails', async () => {
    signIn.mockResolvedValue({ error: 'Invalid login credentials' });
    await render(<SignInScreen />);

    await fillForm('me@example.com', 'wrong');
    await fireEvent.press(screen.getByRole('button', { name: 'Sign in' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('Invalid login credentials');
  });

  it('creates an account and tells the user to confirm their email', async () => {
    signUp.mockResolvedValue({ error: null, needsConfirmation: true });
    await render(<SignInScreen />);

    await fillForm('new@example.com', 'hunter22');
    await fireEvent.press(screen.getByRole('button', { name: 'Create account' }));

    expect(signUp).toHaveBeenCalledWith('new@example.com', 'hunter22');
    expect(await screen.findByText(/check your email/i)).toBeTruthy();
  });

  it.each(['Sign in', 'Create account'])(
    '%s asks for both fields when either is empty',
    async (name) => {
      await render(<SignInScreen />);

      await fillForm('me@example.com', '');
      await fireEvent.press(screen.getByRole('button', { name }));

      expect(await screen.findByRole('alert')).toHaveTextContent('Enter your email and password.');
      expect(signIn).not.toHaveBeenCalled();
      expect(signUp).not.toHaveBeenCalled();
    },
  );
});
