# finance-tracker

Application to track my finances

## Running locally

### Prerequisites

- Node.js (LTS) and npm
- A [Supabase](https://supabase.com) project (for the URL and anon key)
- For Android: Android Studio with an emulator or a USB-connected device

### Setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Create your env file and fill in the values from your Supabase project
   (Project Settings → API):

   ```bash
   cp .env.example .env
   ```

   ```
   EXPO_PUBLIC_SUPABASE_URL=
   EXPO_PUBLIC_SUPABASE_ANON_KEY=
   ```

   `.env` is git-ignored. Never commit secrets.

### Run

- **Web:** `npm run web`
- **Android:** `npx expo run:android` (dev build). Expo Go won't work once Plaid is
  added.
- **Dev server only:** `npm start`

### Checks

- `npm test`: run the tests (`npm run test:watch` to watch)
- `npm run check`: typecheck, lint, format check, and tests
