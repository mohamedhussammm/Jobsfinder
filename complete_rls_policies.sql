-- COMPREHENSIVE RLS POLICIES FOR ALL TABLES
-- This script sets up Row Level Security for the entire application

-- ============================================
-- 1. HELPER FUNCTION (Already created in fix_recursion.sql)
-- ============================================
-- This function is used by all policies to check if user is admin
-- It bypasses RLS to prevent infinite recursion

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

-- ============================================
-- 2. USERS TABLE POLICIES
-- ============================================

-- Users can view their own profile
drop policy if exists "Users can view own profile" on public.users;
create policy "Users can view own profile"
  on public.users for select
  using (auth.uid() = id);

-- Users can update their own profile
drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id);

-- Users can insert their own profile (for registration fallback)
drop policy if exists "Users can insert own profile" on public.users;
create policy "Users can insert own profile"
  on public.users for insert
  with check (auth.uid() = id);

-- Admins can view all users (already created in fix_recursion.sql)
-- Admins can update all users (already created in fix_recursion.sql)

-- ============================================
-- 3. EVENTS TABLE POLICIES
-- ============================================

-- Everyone can view published events
drop policy if exists "Anyone can view published events" on public.events;
create policy "Anyone can view published events"
  on public.events for select
  using (status = 'published');

-- Companies can view their own events (all statuses)
drop policy if exists "Companies can view own events" on public.events;
create policy "Companies can view own events"
  on public.events for select
  using (
    company_id in (
      select id from public.companies
      where user_id = auth.uid()
    )
  );

-- Companies can create event requests (pending status)
drop policy if exists "Companies can create events" on public.events;
create policy "Companies can create events"
  on public.events for insert
  with check (
    company_id in (
      select id from public.companies
      where user_id = auth.uid()
    )
    and status = 'pending'
  );

-- Companies can update their own pending events
drop policy if exists "Companies can update pending events" on public.events;
create policy "Companies can update pending events"
  on public.events for update
  using (
    company_id in (
      select id from public.companies
      where user_id = auth.uid()
    )
    and status = 'pending'
  );

-- Admins can create events (published directly)
drop policy if exists "Admins can create events" on public.events;
create policy "Admins can create events"
  on public.events for insert
  with check (public.is_admin());

-- Admins can view all events (already created in fix_recursion.sql)
-- Admins can update all events (already created in fix_recursion.sql)
-- Admins can delete events (already created in fix_recursion.sql)

-- ============================================
-- 4. APPLICATIONS TABLE POLICIES
-- ============================================

-- Users can view their own applications
drop policy if exists "Users can view own applications" on public.applications;
create policy "Users can view own applications"
  on public.applications for select
  using (user_id = auth.uid());

-- Users can create applications
drop policy if exists "Users can create applications" on public.applications;
create policy "Users can create applications"
  on public.applications for insert
  with check (user_id = auth.uid());

-- Users can delete their own applications (withdraw)
drop policy if exists "Users can withdraw applications" on public.applications;
create policy "Users can withdraw applications"
  on public.applications for delete
  using (user_id = auth.uid() and status = 'applied');

-- Companies can view applications for their events
drop policy if exists "Companies can view event applications" on public.applications;
create policy "Companies can view event applications"
  on public.applications for select
  using (
    event_id in (
      select id from public.events
      where company_id in (
        select id from public.companies
        where user_id = auth.uid()
      )
    )
  );

-- Team Leaders can view applications for assigned events
drop policy if exists "Team leaders can view assigned applications" on public.applications;
create policy "Team leaders can view assigned applications"
  on public.applications for select
  using (
    event_id in (
      select event_id from public.team_leaders
      where user_id = auth.uid()
      and status = 'assigned'
    )
  );

-- Team Leaders can update application status
drop policy if exists "Team leaders can update applications" on public.applications;
create policy "Team leaders can update applications"
  on public.applications for update
  using (
    event_id in (
      select event_id from public.team_leaders
      where user_id = auth.uid()
      and status = 'assigned'
    )
  );

-- ============================================
-- 5. COMPANIES TABLE POLICIES
-- ============================================

-- Everyone can view verified companies
drop policy if exists "Anyone can view verified companies" on public.companies;
create policy "Anyone can view verified companies"
  on public.companies for select
  using (verified = true);

-- Company users can view their own company
drop policy if exists "Company users can view own company" on public.companies;
create policy "Company users can view own company"
  on public.companies for select
  using (user_id = auth.uid());

-- Company users can update their own company
drop policy if exists "Company users can update own company" on public.companies;
create policy "Company users can update own company"
  on public.companies for update
  using (user_id = auth.uid());

-- Admins can view all companies (already created in fix_recursion.sql)

-- ============================================
-- 6. TEAM LEADERS TABLE POLICIES
-- ============================================

-- Team leaders can view their assignments
drop policy if exists "Team leaders can view assignments" on public.team_leaders;
create policy "Team leaders can view assignments"
  on public.team_leaders for select
  using (user_id = auth.uid());

-- Admins can manage team leaders (already created in fix_recursion.sql)

-- ============================================
-- 7. RATINGS TABLE POLICIES
-- ============================================

-- Users can view their own ratings
drop policy if exists "Users can view own ratings" on public.ratings;
create policy "Users can view own ratings"
  on public.ratings for select
  using (rated_user_id = auth.uid());

-- Team leaders can create ratings
drop policy if exists "Team leaders can create ratings" on public.ratings;
create policy "Team leaders can create ratings"
  on public.ratings for insert
  with check (
    rater_id = auth.uid()
    and rater_id in (
      select user_id from public.team_leaders
      where status = 'assigned'
    )
  );

-- ============================================
-- 8. AUDIT LOGS TABLE POLICIES
-- ============================================

-- Only admins can view audit logs
drop policy if exists "Admins can view audit logs" on public.audit_logs;
create policy "Admins can view audit logs"
  on public.audit_logs for select
  using (public.is_admin());

-- Only admins can create audit logs
drop policy if exists "Admins can create audit logs" on public.audit_logs;
create policy "Admins can create audit logs"
  on public.audit_logs for insert
  with check (public.is_admin());
