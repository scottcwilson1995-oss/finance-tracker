# Finance Tracker — Plan

Personal finance app for Android (installed on a Pixel via the Play Store) and the web.
It pulls transactions from bank accounts, categorizes spending, tracks budgets and
savings goals, and will later add AI insights.

**Status:** Phase 0 (setup) complete. Next: Phase 1 (sign-in, database schema).

---

## Decisions

| Date       | Decision                                                                           | Why                                                                               |
| ---------- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 2026-11-01 | Personal use only (Scott)                                                          | Keeps compliance light; install via Play Store _internal testing_ track           |
| 2026-11-01 | Plaid for bank connections                                                         | Broadest US bank coverage, built-in transaction categories                        |
| 2026-11-01 | Expo (React Native + TypeScript) for Android + web                                 | One codebase for both platforms                                                   |
| 2026-11-01 | Supabase for database, auth, server functions                                      | Postgres + login + Edge Functions in one place                                    |
| 2026-11-01 | TDD (red-green-refactor, one test at a time)                                       | Per global CLAUDE.md protocol                                                     |
| 2026-11-01 | Use Plaid Transactions + Liabilities + Investments                                 | Cover spending, card/loan due dates, and retirement/brokerage balances            |
| 2026-11-01 | Support manual accounts                                                            | Whole life insurance and likely Onity aren't available through Plaid              |
| 2026-11-01 | Push notifications for upcoming payments (`expo-notifications`)                    | Credit card and mortgage due-date reminders                                       |
| 2026-11-01 | Personal loans as manual accounts (I owe / owed to me)                             | Track loans that aren't at a Plaid-connected bank, including loans between people |
| 2026-11-01 | Recurring detection via Plaid + own backup logic; fixed/variable labels            | Spot subscriptions/bills and separate fixed from variable spending                |
| 2026-11-01 | Income from bank deposits + manual entry first; payroll connections explored later | Deposits cover net pay with no extra setup; payroll APIs are business-oriented    |
| 2026-11-01 | Full paycheck breakdown + contributions tracker with IRS limit progress            | See taxes, insurance, and 401(k)/HSA contributions per paycheck and YTD           |
| 2026-11-01 | Hosted Supabase project for development (no local Docker)                          | Docker no longer supports macOS 12                                                |
| 2026-11-01 | Build Android app with EAS cloud builds                                            | Avoids installing Android Studio on this Mac                                      |
| 2026-11-01 | Web output is static (`web.output: static`)                                        | Simple hosting (e.g. Vercel)                                                      |

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
- `accounts`: checking, savings, credit cards, loans, investments; `source` = plaid or manual
- `liabilities`: credit card and loan details (statement balance, minimum payment, due date, rate)
- `balance_snapshots`: daily balance per account, for net worth history
- `holdings`: investment positions (Phase 2+, optional detail)
- `payment_reminders`: when to notify before each due date
- `loan_payments`: payments logged against manual loans (personal loans, Onity if manual)
- `recurring_streams`: detected or manual recurring charges (merchant, frequency, average amount, next date, status, fixed/variable)
- `categories.expense_type` and per-transaction override: fixed or variable
- `income_sources`: employer/side income/etc. with expected amount, frequency, next payday; linked deposits
- `paychecks`: one per pay date (gross, net, linked bank deposit)
- `paycheck_lines`: each line item, typed (earning / non-taxable earning / tax / insurance / retirement / HSA / employer benefit / other), payer (employee or employer), pre- or post-tax, which tax wages it reduces (federal/state, FICA), linked account for contributions, this-period and YTD amounts
- `paycheck_templates`: reusable default breakdown so each payday is one tap
- `contribution_limits`: IRS limits per year (401(k), HSA, IRA)
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

- [x] Scaffold Expo project (SDK 58, TypeScript, Expo Router) with five tabs as placeholder screens
- [x] ESLint + Prettier (`npm run lint`, `npm run format`)
- [x] Jest + React Native Testing Library (`npm test`), 14 tests
- [x] Hosted Supabase project created; app connects (verified: auth endpoint returns 200)
- [x] Supabase client: encrypted session storage on Android, browser storage on web
- [x] `.env` handling (`.env` git-ignored, `.env.example` committed)
- [x] GitHub repo
- [x] Web build works (`npx expo export --platform web`); `expo-doctor` 20/20
- [ ] Moved to Phase 1: install Supabase CLI and link the project (for database migrations)

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

### Phase 2b – Accounts, balances & payment reminders

- [ ] Accounts tab grouped by type: Cash, Credit cards, Loans, Investments & retirement, Insurance
- [ ] Current balance for every account; net worth total on Overview
- [ ] Credit cards: balance, statement balance, minimum payment, due date (Plaid Liabilities)
- [ ] Mortgages: principal balance, rate, monthly payment, next due date
- [ ] Manual accounts (Onity, whole life, anything Plaid can't connect) with editable balance and due date
- [ ] Personal loans (manual), either direction:
  - Money I owe (bank/online lender, family/friend) or money owed to me
  - Fields: name, other party, original amount, rate (0% allowed), start date, payment amount + frequency, due day
  - Log payments; remaining balance and payoff date calculated (amortization when rate > 0)
  - "Owed to me" loans count as assets in net worth, "I owe" loans as debts
  - Due dates feed the upcoming payments list and reminders
- [ ] "Upcoming payments" list on Overview (next 30 days)
- [ ] Push notifications before a payment is due (e.g. 5 days and 1 day before; configurable)
- [ ] Daily balance snapshots so we can chart net worth over time

### Phase 3 – Spending tab

- [ ] Transaction list (newest first, infinite scroll)
- [ ] Search and filter by date range, account, category
- [ ] Spending by category chart (donut/pie)
- [ ] Spending over time chart (bar by week/month)
- [ ] Tap a transaction to change its category
- [ ] "Apply to all from this merchant" creates a `category_rule`
- [ ] Manage categories (add, rename, color)

### Phase 3b – Recurring charges & fixed/variable expenses

- [ ] Detect recurring charges with Plaid's recurring transactions endpoint (`/transactions/recurring/get`): merchant, frequency, average amount, last/next date
- [ ] Our own detection as a backup (same merchant, regular interval, similar amount) for manual accounts or anything Plaid misses
- [ ] "Recurring" screen: subscriptions and bills, monthly total, next expected date
- [ ] Confirm, dismiss, or manually add a recurring charge
- [ ] Alerts: new subscription detected, price went up, expected charge didn't arrive
- [ ] Label each expense **fixed** (same amount each time: mortgage, insurance, subscriptions) or **variable** (groceries, dining, gas, utilities)
  - Auto-suggest from amount consistency; user can override per recurring charge or per category
- [ ] Spending tab and Overview show fixed vs. variable totals per month
- [ ] Recurring charges and mortgage/loan payments feed the upcoming payments list

### Phase 3c – Income

- [ ] Detect income from bank deposits: Plaid's recurring endpoint also returns _inflow_ streams (paychecks, transfers in) with frequency and average amount
- [ ] Income sources list: employer paychecks, side income, rental, interest/dividends, other
- [ ] Add manual income (one-time or recurring: amount, frequency, next date) for anything not deposited to a connected account
- [ ] Mark deposits as income vs. not income (transfers between my own accounts, refunds, loan repayments owed to me)
- [ ] **Paycheck breakdown** (per paycheck, with month and year-to-date totals):
  - Gross pay (salary/hourly, overtime, bonus)
  - Taxes: federal, state, Social Security, Medicare, local
  - Insurance: medical, dental, vision, life, disability
  - Contributions: 401(k) pre-tax and Roth, HSA, other investment/ESPP
  - Other deductions (e.g. FSA, garnishments, union dues)
  - Net pay, matched to the actual bank deposit
  - Visual: gross-to-net chart showing where each dollar of the paycheck goes
- [ ] **Contributions tracker:**
  - Per-paycheck and YTD contributions to each account (Principal 401(k), Fidelity HSA, etc.)
  - Employer match / employer HSA contributions shown separately
  - Contribution % of gross pay
  - Progress toward IRS annual limits (401(k), HSA, IRA) with a warning when on pace to exceed or fall short
  - Cross-check against the deposits seen in the linked Principal/Fidelity accounts (Plaid Investments)
- [ ] **Paycheck template based on the real BambooHR stub layout** (no personal numbers stored in this repo):
  - Pay schedule: **monthly** (period = calendar month, pay date the 5th of the following month). Tax-year totals follow the _pay date_.
  - Earnings: Regular (hours: worked + holiday), Non-taxable reimbursements (e.g. mileage). Reimbursements count as income but not taxable wages.
  - Taxes: Federal, State (IA), Social Security, Medicare, each with "wages this period" since taxable wages differ per tax
  - Pre-tax deductions, and _which taxes they reduce_:
    - Medical, Dental, HSA (Section 125): reduce federal, state **and** FICA wages
    - Traditional 401(k): reduces federal and state wages only (still pays FICA)
  - Post-tax deductions: Roth 401(k)
  - Employer contributions (shown separately, not in take-home): 401(k) match, employer share of medical/dental, employer-paid life and long-term disability
  - Withholding settings (filing status, extra withholding): stored so we can estimate year-end tax later
  - Summary cards like the stub: Gross → Taxes % → Deductions % → Take-home %
- [ ] **Total compensation view:** gross pay + all employer-paid benefits and match
- [ ] Validation: computed taxable wages and net pay must match the stub (gross − pre-tax = taxable wages; gross − taxes − deductions = net)
- [ ] Paycheck data entry: manual template (enter once, reuse each payday, edit when amounts change), then pay stub upload (Phase 7) or payroll connection if available
- [ ] Cash flow view: income vs. spending per month, savings rate
- [ ] Expected paydays shown alongside upcoming payments

**Connecting to income sources (explore):**

| Option                                                | What it gives                                                                         | Fit for a personal app                                                                                                                                                                                           |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Bank deposits via Plaid (above)                       | Net pay amounts and dates                                                             | Best default; no extra connections                                                                                                                                                                               |
| Plaid Income (Bank Income / Payroll Income)           | Payroll provider data: gross pay, deductions, pay stubs                               | Aimed at lenders; needs separate Plaid approval and pricing                                                                                                                                                      |
| Payroll APIs (Argyle, Pinwheel, Atomic, Truv)         | Direct connection to ADP, Workday, Gusto, etc.                                        | Built for businesses; contract-based, likely overkill                                                                                                                                                            |
| Pay stub upload (PDF/photo) → AI extraction (Phase 7) | Gross pay and deductions from each stub                                               | Cheap, works with any employer                                                                                                                                                                                   |
| **BambooHR** (Scott's employer)                       | Has a REST API; users can create personal API keys that inherit their own permissions | Explore: confirm (1) employer runs payroll in BambooHR Payroll vs. another provider, (2) employer allows API keys, (3) pay stub data is reachable via API. Fallback: download PDF stubs from BambooHR and upload |

### Phase 4 – Budgets

- [ ] Set a monthly amount per category
- [ ] Budget split into fixed (pre-filled from recurring charges) and variable (what's left to plan)
- [ ] Budget starts from expected monthly income: income − fixed − savings goals = available for variable spending
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
- [ ] Pay stub upload → extract gross pay and deductions into `paychecks`
- [ ] Insights card on Overview tab

---

## Bank tracker

"Expected" values are based on Plaid's known coverage and must be **confirmed in Phase 2**
with Plaid's `/institutions/search` endpoint (shows supported products + OAuth for each bank).

**Plaid products we need:** Transactions (spending), Liabilities (card/mortgage balances,
due dates, minimum payments), Investments (401k, IRAs, HSA, brokerage).

| Institution               | Accounts                  | Plaid product             | Expected support | OAuth?  | Status    | Notes                                                       |
| ------------------------- | ------------------------- | ------------------------- | ---------------- | ------- | --------- | ----------------------------------------------------------- |
| Wells Fargo               | Checking, Savings         | Transactions              | Yes              | Yes     | To verify |                                                             |
| Wells Fargo               | Credit card               | Transactions, Liabilities | Yes              | Yes     | To verify | Same login as checking, one connection                      |
| GreenState Credit Union   | Checking                  | Transactions              | Likely           | Unknown | To verify |                                                             |
| GreenState Credit Union   | Mortgage                  | Liabilities               | Uncertain        | Unknown | To verify | Plaid mortgage detail covers fewer banks; manual fallback   |
| Citi                      | Credit card               | Transactions, Liabilities | Yes              | Yes     | To verify |                                                             |
| Bank of America           | Credit card               | Transactions, Liabilities | Yes              | Yes     | To verify |                                                             |
| Onity (mortgage servicer) | Mortgage                  | Liabilities               | Unlikely         | Unknown | To verify | Probably a manual account: balance, rate, due date, payment |
| Principal Financial       | 401(k)                    | Investments               | Likely           | Unknown | To verify |                                                             |
| Northwestern Mutual       | Roth IRA, Traditional IRA | Investments               | Uncertain        | Unknown | To verify | Manual fallback if unsupported                              |
| Northwestern Mutual       | Whole life insurance      | —                         | No               | —       | Manual    | Plaid doesn't cover insurance; track cash value manually    |
| Fidelity Investments      | HSA                       | Investments               | Yes              | Yes     | To verify |                                                             |
| Robinhood                 | Individual brokerage      | Investments               | Yes              | Yes     | To verify |                                                             |

**Fallback for anything Plaid can't connect:** manual accounts. You enter the balance (and for
loans: rate, payment, due date) and update it when you like. They still count in net worth
and payment reminders.

---

## Open items

- [x] Scott to send the list of banks/cards (2026-11-01)
- [ ] Confirm each institution in Plaid (`/institutions/search`) once Plaid keys exist
- [ ] Check Plaid pricing for Liabilities + Investments + Recurring Transactions (billed on top of Transactions)
- [x] Payroll provider: BambooHR (2026-11-01)
- [x] Pay stub reviewed (2026-11-01); template structure added to Phase 3c. The stub itself stays out of the repo.
- [x] HSA coverage: self-only (2026 limit $4,400)
- [ ] Check BambooHR: payroll module in use? API keys allowed? Pay stub endpoint?
- [ ] Scott: any other income sources?
- [ ] Ask Plaid whether Payroll Income is available for a personal-use app
- [ ] Plaid production access approval (sandbox works right away)
- [ ] Accounts to create: Supabase, Plaid, Google Play Console, Expo (EAS), Anthropic API key (Phase 7)
