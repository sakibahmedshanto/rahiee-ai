-- Email Verification Configuration for Rahiee AI
-- This ensures proper email verification flow for signup

-- 1. First, make sure your Supabase project has email configuration:
--    Go to Authentication > Settings > SMTP Settings in your Supabase dashboard
--    Configure your email provider (Gmail, SendGrid, etc.)

-- 2. Configure email templates:
--    Go to Authentication > Templates in your Supabase dashboard
--    Customize the "Confirm signup" email template

-- 3. Update auth settings to require email confirmation:
--    In your Supabase dashboard, go to Authentication > Settings
--    Set "Email confirmations" to "Enable email confirmations"
--    Set "Double confirm email changes" if desired

-- 4. Update the RLS policy to allow only verified users to insert profiles:
DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON public.my_users;

-- Allow only verified users to create their profile
CREATE POLICY "Verified users can insert own profile" ON public.my_users
    FOR INSERT WITH CHECK (
        auth.uid() = id 
        AND auth.role() = 'authenticated'
        AND auth.email_confirmed_at() IS NOT NULL
    );

-- Also update the existing policies to be more specific
DROP POLICY IF EXISTS "Users can view own profile" ON public.my_users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.my_users;

-- Only allow access to users who have verified their email
CREATE POLICY "Verified users can view own profile" ON public.my_users
    FOR SELECT USING (
        auth.uid() = id 
        AND auth.email_confirmed_at() IS NOT NULL
    );

CREATE POLICY "Verified users can update own profile" ON public.my_users
    FOR UPDATE USING (
        auth.uid() = id 
        AND auth.email_confirmed_at() IS NOT NULL
    );

-- Function to check if current user is verified
CREATE OR REPLACE FUNCTION is_user_verified()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.email_confirmed_at() IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_user_verified() TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Email verification policies updated successfully!';
    RAISE NOTICE 'Make sure to configure SMTP settings in your Supabase dashboard';
    RAISE NOTICE 'Enable email confirmations in Authentication > Settings';
END $$;
