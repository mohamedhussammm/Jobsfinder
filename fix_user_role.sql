-- Fix user with role='user' to role='normal'
-- This fixes the dropdown error in admin user management

UPDATE public.users 
SET role = 'normal' 
WHERE role = 'user';

-- Verify the fix
SELECT id, email, name, role 
FROM public.users 
WHERE role IN ('user', 'normal')
ORDER BY email;
