import { Tabs } from 'expo-router';

import Colors from '@/constants/Colors';
import { useColorScheme } from '@/components/useColorScheme';
import { useClientOnlyValue } from '@/components/useClientOnlyValue';

export default function TabLayout() {
  const colorScheme = useColorScheme();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Colors[colorScheme].tint,
        // Disable the static render of the header on web
        // to prevent a hydration error in React Navigation.
        headerShown: useClientOnlyValue(false, true),
      }}
    >
      <Tabs.Screen name="index" options={{ title: 'Overview' }} />
      <Tabs.Screen name="spending" options={{ title: 'Spending' }} />
      <Tabs.Screen name="budget" options={{ title: 'Budget' }} />
      <Tabs.Screen name="goals" options={{ title: 'Goals' }} />
      <Tabs.Screen name="accounts" options={{ title: 'Accounts' }} />
    </Tabs>
  );
}
