# Finance Tracker — Plan

Personal finance app for Android (installed on a Pixel via the Play Store) and the web.
It pulls transactions from bank accounts, categorizes spending, tracks budgets and
savings goals, and will later add AI insights.

**Status:** Planning complete. Phase 0 not started.

---

## Decisions

| Date | Decision | Why |
|---|---|---|
| 2026-11-01 | Personal use only (Scott) | Keeps compliance light; install via Play Store *internal testing* track |
| 2026-11-01 | Plaid for bank connections | Broadest US bank coverage, built-in transaction categories |
| 2026-11-01 | Expo (React Native + TypeScript) for Android + web | One codebase for both platforms |
| 2026-11-01 | Supabase for database, auth, server functions | Postgres + login + Edge Functions in one place |
| 2026-11-01 | TDD (red-green-refactor, one test at a time) | Per global CLAUDE.md protocol |

---

## Architecture

**App (Expo Router)**: tabs: Overview · Spending · Budget · Goals · Accounts.
The same code builds the Android app and the website (`expo export --platform web`).

**Backend (Supabase)**
- Auth: email or Google sign-in.
- Row Level Security (RLS) on every table, so only the signed-in user can read their data.
- Edge Functions (server-side only):
  - `plaid-link-token`: starts a Plaid Link session
  - `plaid-exchange`: swaps the public token for an access token and stores it
  - `plaid-sync`: pulls new/changed transactions via `/transactions/sync`
  - `plaid-webhook`: Plaid calls this when new data is ready
  - `ai-insights` (Phase 7)
- Plaid access tokens are stored encrypted (Supabase Vault) and **never** sent to the phone or browser.

**Data model**
- `plaid_items`: one per bank login
- `accounts`: checking, savings, credit cards, etc.
- `transactions`: includes `plaid_category`, `category_id`, `category_source` (plaid / rule / manual)
- `categories`: default set plus your own
- `category_rules`: e.g. "merchant contains STARBUCKS → Coffee", applied to future transactions
- `budgets`, `budget_lines`: monthly amount per category
- `savings_goals`, `goal_contributions`

**Categorization order:** a manual edit beats a user rule, and a user rule beats Plaid's category. The original Plaid category is always kept, so edits can be undone.

**Libraries**
- Charts: `react-native-gifted-charts` (SVG, so it works on Android and web)
- Plaid Link: `react-native-plaid-link-sdk` (Android), `react-plaid-link` (web). Needs an Expo **development build**; Expo Go won't work.

**Testing**
- App: Jest + React Native Testing Library
- Edge Functions: `deno test`
- Database: SQL tests for RLS policies

---

## Roadmap

### Phase 0 – Setup
- [ ] Scaffold Expo project (TypeScript, Expo Router)
- [ ] ESLint + Prettier
- [ ] Jest + React Native Testing Library, with one passing smoke test
- [ ] Create Supabase project; install Supabase CLI; run local Supabase
- [ ] `.env` handling (no secrets in git)
- [ ] GitHub repo (optional)

### Phase 1 – Foundations
- [ ] Sign in / sign out (email, then Google)
- [ ] Database schema migrations for all tables above
- [ ] RLS policies + tests
- [ ] Tab navigation shell (Overview, Spending, Budget, Goals, Accounts)
- [ ] Seed default categories

### Phase 2 – Bank connections (Plaid)
- [ ] Plaid developer account; sandbox keys
- [ ] `plaid-link-token` + `plaid-exchange` Edge Functions
- [ ] Plaid Link button on Accounts tab (Android + web)
- [ ] `plaid-sync` stores accounts + transactions
- [ ] `plaid-webhook` triggers sync automatically
- [ ] Verify end to end with sandbox login `user_good` / `pass_good`
- [ ] Fill in the Bank tracker below
- [ ] Apply for Plaid production / limited-production access for real accounts
- [ ] Register Android package name + OAuth redirect for OAuth banks

### Phase 3 – Spending tab
- [ ] Transaction list (newest first, infinite scroll)
- [ ] Search and filter by date range, account, category
- [ ] Spending by category chart (donut/pie)
- [ ] Spending over time chart (bar by week/month)
- [ ] Tap a transaction to change its category
- [ ] "Apply to all from this merchant" creates a `category_rule`
- [ ] Manage categories (add, rename, color)

### Phase 4 – Budgets
- [ ] Set a monthly amount per category
- [ ] Budget vs. actual progress bars
- [ ] Optional rollover of unspent amounts
- [ ] Overview tab shows this month's budget health

### Phase 5 – Savings goals
- [ ] Create goal: name, target amount, target date (e.g. trip, large purchase)
- [ ] Add contributions manually or link a savings account
- [ ] Progress bar + "save $X/month to hit your date"
- [ ] Goals summary on Overview tab

### Phase 6 – Release
- [ ] Google Play Console developer account ($25 one-time)
- [ ] Expo EAS account; `eas build` → Android App Bundle (AAB)
- [ ] Upload to Play Store **internal testing** track; install on Pixel
- [ ] Deploy web build (e.g. Vercel)

### Phase 7 – AI insights
- [ ] `ai-insights` Edge Function calling the Claude API
- [ ] Send **aggregated** data only (category totals, trends), no account numbers
- [ ] Insights: spending trends, unusual charges, budget suggestions, goal forecasts
- [ ] Insights card on Overview tab

---

## Bank tracker

Add each bank/card here, then check Plaid support in Phase 2.

| Bank / card | In Plaid? | OAuth? | Status | Notes |
|---|---|---|---|---|
| | | | | |

---

## Open items
- [ ] Scott to send the list of banks/cards
- [ ] Plaid production access approval (sandbox works right away)
- [ ] Accounts to create: Supabase, Plaid, Google Play Console, Expo (EAS), Anthropic API key (Phase 7)
