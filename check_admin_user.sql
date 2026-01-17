-- DEBUG: Check if admin user exists and has correct role
-- Run this to see what's in your users table

SELECT id, email, role 
FROM public.users 
WHERE email = 'admin@shiftsphere.com';

-- If the admin user doesn't exist or doesn't have role='admin', 
-- you need to create/update it:

-- Option 1: If admin user exists but wrong role
-- UPDATE public.users 
-- SET role = 'admin' 
-- WHERE email = 'admin@shiftsphere.com';

-- Option 2: If admin user doesn't exist at all, create it
-- You need to first register via the app, then run:
-- UPDATE public.users 
-- SET role = 'admin' 
-- WHERE email = 'admin@shiftsphere.com';
