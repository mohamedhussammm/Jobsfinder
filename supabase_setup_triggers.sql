-- Database Setup Script (Robust Version)
-- This script sets up a "Trigger" that automatically creates a user profile
-- whenever a new user signs up via Supabase Auth.
-- This bypasses client-side RLS issues entirely.

-- 1. Create the users table if it doesn't exist
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique not null,
  name text,
  role text not null default 'user',
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

-- 3. Create the function that handles new user creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (
    id,
    email,
    name,
    role,
    phone,
    national_id_number
  )
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'role', 'user'),
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'national_id_number', 'PENDING')
  );
  return new;
end;
$$ language plpgsql security definer;

-- 4. Create the trigger
-- Drop existing trigger if it exists to avoid errors
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();

-- 5. Create basic RLS policies for viewing/updating own profile
-- Drop existing policies first to act as a "Reset"
drop policy if exists "Enable insert for users based on user_id" on public.users;
drop policy if exists "Enable select for users based on user_id" on public.users;
drop policy if exists "Enable update for users based on user_id" on public.users;

-- We don't need an INSERT policy anymore because the trigger handles it!

create policy "Enable select for users based on user_id"
  on public.users for select
  using ( auth.uid() = id );

create policy "Enable update for users based on user_id"
  on public.users for update
  using ( auth.uid() = id );
