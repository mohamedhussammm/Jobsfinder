-- Enable Row Level Security (RLS) on the users table
-- Run this in your Supabase SQL Editor

-- 1. Create the users table if it doesn't exist
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique not null,
  name text,
  role text not null default 'user', -- 'admin', 'user', 'team_leader', 'company'
  phone text,
  national_id_number text,
  avatar_path text,
  profile_complete boolean default false,
  rating_avg decimal default 0,
  rating_count integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  deleted_at timestamp with time zone
);

-- 2. Enable RLS
alter table public.users enable row level security;

-- 3. Create Policy: Allow users to insert their OWN profile
-- This is required because your app creates the profile client-side after sign-up
create policy "Enable insert for users based on user_id"
  on public.users for insert
  with check ( auth.uid() = id );

-- 4. Create Policy: Allow users to view their OWN profile
create policy "Enable select for users based on user_id"
  on public.users for select
  using ( auth.uid() = id );

-- 5. Create Policy: Allow users to update their OWN profile
create policy "Enable update for users based on user_id"
  on public.users for update
  using ( auth.uid() = id );

-- 6. Grant usage to authenticated users (standard practice)
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all privileges on all tables in schema public to postgres, anon, authenticated, service_role;
