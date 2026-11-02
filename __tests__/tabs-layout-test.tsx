import { Text } from 'react-native';
import { renderRouter, screen } from 'expo-router/testing-library';

import TabLayout from '@/app/(tabs)/_layout';

const Stub = () => <Text>screen</Text>;

describe('Tab layout', () => {
  it('shows the five main tabs', async () => {
    await renderRouter({
      '(tabs)/_layout': TabLayout,
      '(tabs)/index': Stub,
      '(tabs)/spending': Stub,
      '(tabs)/budget': Stub,
      '(tabs)/goals': Stub,
      '(tabs)/accounts': Stub,
    });

    for (const label of ['Overview', 'Spending', 'Budget', 'Goals', 'Accounts']) {
      expect(screen.getAllByText(label).length).toBeGreaterThan(0);
    }
  });
});
