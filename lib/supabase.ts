import { createClient } from '@supabase/supabase-js';

import { SecureSessionStorage } from '@/lib/secureSessionStorage';
import { supabaseConfigFromEnv } from '@/lib/supabaseConfig';

const { url, key } = supabaseConfigFromEnv();

export const supabase = createClient(url, key, {
  auth: {
    storage: new SecureSessionStorage(),
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
  },
});
