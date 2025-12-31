-- FINAL FIX: Restore permissions for App to save user profiles
-- The error "new row violates row-level security policy" happens because we removed the "INSERT" permission.
-- We need to add it back so the app can save the missing profile.

-- 1. Enable RLS (Standard)
alter table public.users enable row level security;

-- 2. Allow App to INSERT (Save) the user's own profile
-- This fixes the error you see during Login/Registration fallback
create policy "Enable insert for users based on user_id"
  on public.users for insert
  with check ( auth.uid() = id );

-- 3. Allow App to SELECT (Read) the user's own profile
-- Drop first to avoid duplicates
drop policy if exists "Enable select for users based on user_id" on public.users;
create policy "Enable select for users based on user_id"
  on public.users for select
  using ( auth.uid() = id );

-- 4. Allow App to UPDATE (Edit) the user's own profile
drop policy if exists "Enable update for users based on user_id" on public.users;
create policy "Enable update for users based on user_id"
  on public.users for update
  using ( auth.uid() = id );
