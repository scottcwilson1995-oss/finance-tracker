import { render, screen } from '@testing-library/react-native';

import OverviewScreen from '@/app/(tabs)/index';
import SpendingScreen from '@/app/(tabs)/spending';
import BudgetScreen from '@/app/(tabs)/budget';
import GoalsScreen from '@/app/(tabs)/goals';
import AccountsScreen from '@/app/(tabs)/accounts';

describe('Tab screens', () => {
  it.each([
    ['Overview', OverviewScreen],
    ['Spending', SpendingScreen],
    ['Budget', BudgetScreen],
    ['Goals', GoalsScreen],
    ['Accounts', AccountsScreen],
  ])('%s screen shows its heading', async (title, Screen) => {
    await render(<Screen />);

    expect(screen.getByRole('header', { name: title })).toBeTruthy();
  });
});
