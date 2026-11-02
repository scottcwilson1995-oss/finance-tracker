import { createClient } from '@supabase/supabase-js';

import { supabaseConfigFromEnv } from '@/lib/supabaseConfig';

const { url, key } = supabaseConfigFromEnv();

// On web, Supabase's default browser storage is used (no storage option).
export const supabase = createClient(url, key, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    // OAuth (Google) returns a one-time code that is exchanged for a session.
    flowType: 'pkce',
  },
});
