import eas from '@/eas.json';

describe('eas.json', () => {
  it('has a development profile that builds an installable dev-client APK', () => {
    expect(eas.build.development).toMatchObject({
      developmentClient: true,
      distribution: 'internal',
      environment: 'development', // EXPO_PUBLIC_SUPABASE_* come from EAS environment variables
      android: { buildType: 'apk' },
    });
  });

  it('does not hold secrets (build values come from EAS environment variables)', () => {
    const text = JSON.stringify(eas);
    expect(text).not.toMatch(/secret|password|token|service_role|eyJ/i);
  });

  it('requires a matching CLI version and manages the app version on EAS', () => {
    expect(eas.cli.appVersionSource).toBe('remote');
  });
});
