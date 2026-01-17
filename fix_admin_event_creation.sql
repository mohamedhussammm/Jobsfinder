-- CRITICAL FIX: Admin Event Creation RLS
-- This fixes the "new row violates row level security policy" error

-- First, ensure the is_admin() function exists and works correctly
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
    and role = 'admin'
  );
$$;

-- Drop and recreate the admin insert policy with proper check
drop policy if exists "Admins can create events" on public.events;
create policy "Admins can create events"
  on public.events
  for insert
  with check (
    exists (
      select 1
      from public.users
      where id = auth.uid()
      and role = 'admin'
    )
  );

-- Also ensure admins can insert into events table directly
-- Alternative simpler policy (use this if above doesn't work)
drop policy if exists "Admins bypass RLS for events" on public.events;
create policy "Admins bypass RLS for events"
  on public.events
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.users
      where id = auth.uid()
      and role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.users
      where id = auth.uid()
      and role = 'admin'
    )
  );
