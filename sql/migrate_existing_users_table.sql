-- Migration script to update existing my_users table for compatibility with UserModel
-- Run this script in your Supabase SQL Editor

-- First, let's check the current table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'my_users'
ORDER BY ordinal_position;

-- Add missing columns that UserModel expects but might not exist
DO $$
BEGIN
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'updated_at') THEN
        ALTER TABLE public.my_users ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END
$$;

-- Update the id column to allow manual insertion (for signup process)
-- This allows us to use the auth.user.id as the primary key
ALTER TABLE public.my_users ALTER COLUMN id DROP DEFAULT;

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_my_users_updated_at ON public.my_users;
CREATE TRIGGER update_my_users_updated_at
    BEFORE UPDATE ON public.my_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update the RLS policies to be more permissive for the app to work correctly
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.my_users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.my_users;
DROP POLICY IF EXISTS "Allow user creation" ON public.my_users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.my_users;
DROP POLICY IF EXISTS "Admins can update all users" ON public.my_users;
DROP POLICY IF EXISTS "Authenticated users can view all users" ON public.my_users;
DROP POLICY IF EXISTS "Service role full access" ON public.my_users;

-- Create new policies that are compatible with the app
-- Policy: Allow authenticated users to read all user data
CREATE POLICY "Authenticated users can view all users" ON public.my_users
    FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Users can update their own profile data
CREATE POLICY "Users can update own profile" ON public.my_users
    FOR UPDATE USING (auth.uid() = id);

-- Policy: Allow user creation during signup (this is crucial)
CREATE POLICY "Allow authenticated user creation" ON public.my_users
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy: Allow service role to perform all operations
CREATE POLICY "Service role full access" ON public.my_users
    FOR ALL USING (auth.role() = 'service_role');

-- Policy: Allow users to delete their own profile (optional)
CREATE POLICY "Users can delete own profile" ON public.my_users
    FOR DELETE USING (auth.uid() = id);

-- Ensure proper permissions
GRANT ALL ON public.my_users TO authenticated;
GRANT ALL ON public.my_users TO service_role;

-- Create a test function to verify the setup works
CREATE OR REPLACE FUNCTION test_user_operations()
RETURNS TABLE (
    test_name TEXT,
    result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Check if table exists
    RETURN QUERY
    SELECT 
        'Table Existence'::TEXT,
        CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'my_users')
             THEN 'PASS'::TEXT
             ELSE 'FAIL'::TEXT
        END,
        'Checking if my_users table exists'::TEXT;
    
    -- Test 2: Check required columns
    RETURN QUERY
    SELECT 
        'Required Columns'::TEXT,
        CASE WHEN (
            SELECT COUNT(*) FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'my_users' 
            AND column_name IN ('id', 'employee_id', 'username', 'email', 'full_name', 'user_role', 'is_active')
        ) = 7
             THEN 'PASS'::TEXT
             ELSE 'FAIL'::TEXT
        END,
        'Checking if all required columns exist'::TEXT;
    
    -- Test 3: Check RLS is enabled
    RETURN QUERY
    SELECT 
        'RLS Enabled'::TEXT,
        CASE WHEN (
            SELECT relrowsecurity FROM pg_class 
            WHERE relname = 'my_users' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        )
             THEN 'PASS'::TEXT
             ELSE 'FAIL'::TEXT
        END,
        'Checking if Row Level Security is enabled'::TEXT;
    
    -- Test 4: Check policies exist
    RETURN QUERY
    SELECT 
        'RLS Policies'::TEXT,
        CASE WHEN (
            SELECT COUNT(*) FROM pg_policies 
            WHERE tablename = 'my_users' AND schemaname = 'public'
        ) >= 4
             THEN 'PASS'::TEXT
             ELSE 'FAIL'::TEXT
        END,
        'Checking if RLS policies are configured'::TEXT;
        
END;
$$ LANGUAGE plpgsql;

-- Run the test
SELECT * FROM test_user_operations();

-- Display final table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'my_users'
ORDER BY ordinal_position;
