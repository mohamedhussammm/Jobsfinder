-- CHECK AND CREATE TEST USERS
-- Run this to see if users exist and create test data if needed

-- 1. Check if any users exist
SELECT COUNT(*) as user_count FROM public.users;

-- 2. View all existing users
SELECT id, email, name, role, created_at 
FROM public.users 
ORDER BY created_at DESC;

-- 3. If no users exist, create test users
-- (Uncomment and run if needed)

/*
-- Create test normal user
INSERT INTO public.users (id, email, name, role, phone, national_id_number, profile_complete, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'user@test.com',
  'Test User',
  'normal',
  '+1234567890',
  'USER123',
  true,
  NOW(),
  NOW()
);

-- Create test company user
INSERT INTO public.users (id, email, name, role, phone, national_id_number, profile_complete, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'company@test.com',
  'Test Company',
  'company',
  '+1234567891',
  'COMP123',
  true,
  NOW(),
  NOW()
);

-- Create test team leader
INSERT INTO public.users (id, email, name, role, phone, national_id_number, profile_complete, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'leader@test.com',
  'Test Leader',
  'team_leader',
  '+1234567892',
  'LEAD123',
  true,
  NOW(),
  NOW()
);

-- Create admin user (if not using static admin)
INSERT INTO public.users (id, email, name, role, phone, national_id_number, profile_complete, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'admin@shiftsphere.com',
  'Administrator',
  'admin',
  '+1234567893',
  'ADMIN',
  true,
  NOW(),
  NOW()
);
*/

-- 4. Verify users were created
SELECT id, email, name, role FROM public.users;
