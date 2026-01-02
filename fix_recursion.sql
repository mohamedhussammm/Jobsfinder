-- FIX: Resolve Infinite Recursion in RLS Policies
-- The previous policies caused an infinite loop because checking if a user is an admin
-- required reading the 'users' table, which triggered the policy check again, and so on.

-- 1. Create a Secure Function to check Admin status
-- "SECURITY DEFINER" means this function runs with the privileges of the database owner (superuser),
-- effectively bypassing RLS for the query inside it. This breaks the recursion loop.
create or replace function public.is_admin()
returns boolean
language sql
security definer
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
    and role = 'admin'
  );
$$;

-- 2. Update USERS Policies to use the function
drop policy if exists "Admins can view all profiles" on public.users;
create policy "Admins can view all profiles"
  on public.users for select
  using (
    public.is_admin()
  );

drop policy if exists "Admins can update all profiles" on public.users;
create policy "Admins can update all profiles"
  on public.users for update
  using (
    public.is_admin()
  );

-- 3. Update EVENTS Policies
drop policy if exists "Admins can view all events" on public.events;
create policy "Admins can view all events"
  on public.events for select
  using (
    public.is_admin()
  );

drop policy if exists "Admins can update all events" on public.events;
create policy "Admins can update all events"
  on public.events for update
  using (
    public.is_admin()
  );

drop policy if exists "Admins can delete events" on public.events;
create policy "Admins can delete events"
  on public.events for delete
  using (
    public.is_admin()
  );

-- 4. Update COMPANIES Policies
drop policy if exists "Admins can view all companies" on public.companies;
create policy "Admins can view all companies"
  on public.companies for select
  using (
    public.is_admin()
  );

-- 5. Update TEAM LEADERS Policies
drop policy if exists "Admins can manage team leaders" on public.team_leaders;
create policy "Admins can manage team leaders"
  on public.team_leaders for all
  using (
    public.is_admin()
  );
