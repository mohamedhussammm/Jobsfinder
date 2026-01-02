-- FIX: Grant Admin Permissions for RLS
-- This script adds RLS policies to allow Admins to view and manage all data.

-- 1. Get the Admin Role check helper
-- Note: We check if the requesting user's ID exists in the users table with role 'admin'
-- Since we can't easily do recursion in policies without infinite loops, we can use a cleaner approach if available,
-- but for now we will use a direct subquery which is standard pattern.

-- USERS TABLE POLICIES
-- Allow Admins to SELECT all users
create policy "Admins can view all profiles"
  on public.users for select
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );

-- Allow Admins to UPDATE all users (e.g. change roles, block)
create policy "Admins can update all profiles"
  on public.users for update
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );

-- EVENTS TABLE POLICIES
-- Allow Admins to SELECT all events (including pending/draft)
create policy "Admins can view all events"
  on public.events for select
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );

-- Allow Admins to UPDATE all events (Approve/Reject)
create policy "Admins can update all events"
  on public.events for update
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );

-- Allow Admins to DELETE events
create policy "Admins can delete events"
  on public.events for delete
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );

-- COMPANIES TABLE POLICIES
-- Allow Admins to VIEW all companies (for dropdowns)
-- (Assuming companies table RLS is enabled, if not this is harmless specific to RLS)
create policy "Admins can view all companies"
  on public.companies for select
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );

-- TEAM LEADERS TABLE POLICIES
-- Allow Admins to VIEW/MANAGE team leaders
create policy "Admins can manage team leaders"
  on public.team_leaders for all
  using (
    auth.uid() in (
      select id from public.users where role = 'admin'
    )
  );
