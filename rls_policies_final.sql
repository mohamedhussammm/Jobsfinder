-- FINAL CORRECTED RLS POLICIES
-- Matches your exact Supabase database schema

-- ============================================
-- 1. HELPER FUNCTION
-- ============================================
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

drop policy if exists "Users can view own profile" on public.users;
create policy "Users can view own profile"
  on public.users for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.users;
create policy "Users can insert own profile"
  on public.users for insert
  with check (auth.uid() = id);

drop policy if exists "Admins can view all profiles" on public.users;
create policy "Admins can view all profiles"
  on public.users for select
  using (public.is_admin());

drop policy if exists "Admins can update all profiles" on public.users;
create policy "Admins can update all profiles"
  on public.users for update
  using (public.is_admin());

-- ============================================
-- 3. EVENTS TABLE POLICIES
-- ============================================

drop policy if exists "Anyone can view published events" on public.events;
create policy "Anyone can view published events"
  on public.events for select
  using (status = 'published');

drop policy if exists "Admins can view all events" on public.events;
create policy "Admins can view all events"
  on public.events for select
  using (public.is_admin());

drop policy if exists "Admins can update all events" on public.events;
create policy "Admins can update all events"
  on public.events for update
  using (public.is_admin());

drop policy if exists "Admins can delete events" on public.events;
create policy "Admins can delete events"
  on public.events for delete
  using (public.is_admin());

drop policy if exists "Admins can create events" on public.events;
create policy "Admins can create events"
  on public.events for insert
  with check (public.is_admin());

-- ============================================
-- 4. APPLICATIONS TABLE POLICIES
-- ============================================

drop policy if exists "Users can view own applications" on public.applications;
create policy "Users can view own applications"
  on public.applications for select
  using (user_id = auth.uid());

drop policy if exists "Users can create applications" on public.applications;
create policy "Users can create applications"
  on public.applications for insert
  with check (user_id = auth.uid());

drop policy if exists "Users can withdraw applications" on public.applications;
create policy "Users can withdraw applications"
  on public.applications for delete
  using (user_id = auth.uid() and status = 'applied');

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

drop policy if exists "Admins can view all applications" on public.applications;
create policy "Admins can view all applications"
  on public.applications for select
  using (public.is_admin());

-- ============================================
-- 5. COMPANIES TABLE POLICIES
-- ============================================

drop policy if exists "Anyone can view verified companies" on public.companies;
create policy "Anyone can view verified companies"
  on public.companies for select
  using (verified = true);

drop policy if exists "Admins can view all companies" on public.companies;
create policy "Admins can view all companies"
  on public.companies for select
  using (public.is_admin());

drop policy if exists "Admins can update companies" on public.companies;
create policy "Admins can update companies"
  on public.companies for update
  using (public.is_admin());

drop policy if exists "Admins can create companies" on public.companies;
create policy "Admins can create companies"
  on public.companies for insert
  with check (public.is_admin());

-- ============================================
-- 6. TEAM LEADERS TABLE POLICIES
-- ============================================

drop policy if exists "Team leaders can view assignments" on public.team_leaders;
create policy "Team leaders can view assignments"
  on public.team_leaders for select
  using (user_id = auth.uid());

drop policy if exists "Admins can manage team leaders" on public.team_leaders;
create policy "Admins can manage team leaders"
  on public.team_leaders for all
  using (public.is_admin());

-- ============================================
-- 7. RATINGS TABLE POLICIES
-- ============================================

drop policy if exists "Users can view own ratings" on public.ratings;
create policy "Users can view own ratings"
  on public.ratings for select
  using (rated_user_id = auth.uid());

drop policy if exists "Team leaders can create ratings" on public.ratings;
create policy "Team leaders can create ratings"
  on public.ratings for insert
  with check (
    rater_user_id = auth.uid()
    and rater_user_id in (
      select user_id from public.team_leaders
      where status = 'assigned'
    )
  );

drop policy if exists "Admins can view all ratings" on public.ratings;
create policy "Admins can view all ratings"
  on public.ratings for select
  using (public.is_admin());

-- ============================================
-- 8. AUDIT LOGS TABLE POLICIES
-- ============================================

drop policy if exists "Admins can view audit logs" on public.audit_logs;
create policy "Admins can view audit logs"
  on public.audit_logs for select
  using (public.is_admin());

drop policy if exists "Admins can create audit logs" on public.audit_logs;
create policy "Admins can create audit logs"
  on public.audit_logs for insert
  with check (public.is_admin());

-- ============================================
-- 9. NOTIFICATIONS TABLE POLICIES
-- ============================================

drop policy if exists "Users can view own notifications" on public.notifications;
create policy "Users can view own notifications"
  on public.notifications for select
  using (user_id = auth.uid());

drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can update own notifications"
  on public.notifications for update
  using (user_id = auth.uid());

drop policy if exists "System can create notifications" on public.notifications;
create policy "System can create notifications"
  on public.notifications for insert
  with check (true);
