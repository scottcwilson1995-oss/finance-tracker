# Finance Tracker: project instructions

Personal finance app (Android + web). The roadmap and status live in `PLAN.md`.
**Keep `PLAN.md` up to date:** tick checkboxes as work is done, and log new decisions in its Decisions table.

## Stack
- Expo (React Native + TypeScript, Expo Router): one codebase for Android and web
- Supabase: Postgres, Auth, Edge Functions (Deno)
- Plaid for bank data
- Charts: `react-native-gifted-charts`

## Folder layout (planned)
- `app/`: Expo Router screens (tabs: Overview, Spending, Budget, Goals, Accounts)
- `src/`: shared components, hooks, and business logic
- `supabase/migrations/`: database schema
- `supabase/functions/`: Edge Functions (`plaid-*`, `ai-insights`)

## Commands (fill in once scaffolded)
- Test: `npm test`
- Run on web: `npx expo start --web`
- Run on Android: dev build (`npx expo run:android` or EAS); Expo Go won't work with Plaid
- Local backend: `supabase start`

## Rules
- Follow the global TDD protocol: one failing test first, then minimal code, then refactor.
- **Security:** Plaid access tokens and secret keys stay server-side (Edge Functions, Supabase Vault). Never send them to the app, log them, or commit them.
- Every table has Row Level Security, with a test for it.
- Secrets go in `.env` files that are git-ignored.
- AI features send only aggregated data (no account numbers or raw identifiers).
