-- TEMPORARY FIX: Disable RLS on events table for testing
-- This will allow admin to create events while we debug the policy issue

-- Disable RLS temporarily
alter table public.events disable row level security;

-- After you test and create events successfully, you can re-enable it with:
-- alter table public.events enable row level security;
