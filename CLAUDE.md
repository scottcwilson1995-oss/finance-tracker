# Finance Tracker: project instructions

Personal finance app (Android + web). The roadmap and status live in `PLAN.md`.
**Keep `PLAN.md` up to date:** tick checkboxes as work is done, and log new decisions in its Decisions table.

## Stack

- Expo (React Native + TypeScript, Expo Router): one codebase for Android and web
- Supabase: Postgres, Auth, Edge Functions (Deno)
- Plaid for bank data
- Charts: `react-native-gifted-charts`

Also read `AGENTS.md` (Expo's guidance): check the versioned Expo docs for SDK 58 instead of relying on memory, and add packages with `npx expo install`.

## Folder layout

- `app/`: Expo Router routes only (tabs live in `app/(tabs)/`). Never put tests or helpers here.
- `components/`: shared UI components
- `lib/`: business logic and services (`supabase.ts` for Android, `supabase.web.ts` for web)
- `constants/`: colors and other constants
- `__tests__/`: Jest tests, named `*-test.ts(x)`
- Planned: `supabase/migrations/` (database schema), `supabase/functions/` (Edge Functions: `plaid-*`, `ai-insights`)

## Environment

- Node 22 via nvm (`nvm use 22`). Node 26 does not run on this Mac (macOS 12).
- No Docker on this Mac, so use the hosted Supabase project, not `supabase start`.
- Android builds use EAS cloud builds (`npx eas-cli@latest build`), not a local Android Studio.

## Commands

- All checks (run before calling work done): `npm run check` (typecheck + lint + format check + tests)
- Tests: `npm test` (watch mode: `npm run test:watch`)
- Format: `npm run format`
- Run on web: `npm run web`
- Build web: `npx expo export --platform web`
- Health check: `npx expo-doctor`

## Rules

- Follow the global TDD protocol: one failing test first, then minimal code, then refactor.
- **Security:** Plaid access tokens and secret keys stay server-side (Edge Functions, Supabase Vault). Never send them to the app, log them, or commit them.
- Every table has Row Level Security, with a test for it.
- Secrets go in `.env` files that are git-ignored.
- AI features send only aggregated data (no account numbers or raw identifiers).
