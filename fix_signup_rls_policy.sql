-- Quick RLS Policy Fix for Manual Signup Issue
-- Run this in your Supabase SQL Editor to fix the signup problem

-- Drop the problematic policy
DROP POLICY IF EXISTS "Public can insert during signup" ON public.my_users;

-- Create the correct policy that allows users to insert their own profile
CREATE POLICY "Authenticated users can insert own profile" ON public.my_users
    FOR INSERT WITH CHECK (auth.uid() = id AND auth.role() = 'authenticated');

-- Verify the policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'my_users';
