-- Reference patch for Supabase migration add_profile_saved_address (version 20261019193232).
-- This repository does not currently contain the project's full Supabase migration history,
-- so keep this under database/patches rather than implying it is a standalone db-push history.
-- Applied to the Online Ordering Supabase project on 2026-10-19.
alter table public.profiles
  add column if not exists address text;
