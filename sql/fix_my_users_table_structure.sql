-- Updated my_users table structure to match UserModel
-- Run this script in your Supabase SQL Editor to fix the schema

-- Drop existing table if it exists (WARNING: This will delete all data)
-- Comment out the next line if you want to preserve existing data
-- DROP TABLE IF EXISTS public.my_users CASCADE;

-- Check if table exists and has the correct structure
-- If table doesn't exist, create it with the correct structure
DO $$
BEGIN
    -- Create table if it doesn't exist
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'my_users') THEN
        CREATE TABLE public.my_users (
            id UUID PRIMARY KEY,
            employee_id VARCHAR(50) UNIQUE,
            username VARCHAR(100),
            email VARCHAR(255) UNIQUE NOT NULL,
            phone VARCHAR(20),
            user_img TEXT,
            user_device_token TEXT,
            full_name VARCHAR(255) NOT NULL,
            department VARCHAR(100),
            position VARCHAR(100),
            user_role VARCHAR(20) DEFAULT 'employee' CHECK (user_role IN ('employee', 'admin', 'ceo', 'manager')),
            is_active BOOLEAN DEFAULT true,
            created_on TIMESTAMPTZ DEFAULT NOW(),
            work_location VARCHAR(255),
            shift_type VARCHAR(50),
            supervisor_id VARCHAR(50),
            salary_rate DECIMAL(10, 2),
            emergency_contact VARCHAR(255),
            emergency_phone VARCHAR(20),
            biometric_enabled BOOLEAN DEFAULT false,
            preferred_language VARCHAR(10) DEFAULT 'en',
            notifications_enabled BOOLEAN DEFAULT true,
            total_coverage_given INTEGER DEFAULT 0,
            total_coverage_received INTEGER DEFAULT 0,
            attendance_rate DECIMAL(5, 2) DEFAULT 0.0,
            leave_balance INTEGER DEFAULT 30,
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    ELSE
        -- Add missing columns if table exists but structure is different
        -- Check and add each column individually
        
        -- Add employee_id if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'employee_id') THEN
            ALTER TABLE public.my_users ADD COLUMN employee_id VARCHAR(50) UNIQUE;
        END IF;
        
        -- Add username if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'username') THEN
            ALTER TABLE public.my_users ADD COLUMN username VARCHAR(100);
        END IF;
        
        -- Add phone if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'phone') THEN
            ALTER TABLE public.my_users ADD COLUMN phone VARCHAR(20);
        END IF;
        
        -- Add user_img if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'user_img') THEN
            ALTER TABLE public.my_users ADD COLUMN user_img TEXT;
        END IF;
        
        -- Add user_device_token if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'user_device_token') THEN
            ALTER TABLE public.my_users ADD COLUMN user_device_token TEXT;
        END IF;
        
        -- Add department if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'department') THEN
            ALTER TABLE public.my_users ADD COLUMN department VARCHAR(100);
        END IF;
        
        -- Add position if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'position') THEN
            ALTER TABLE public.my_users ADD COLUMN position VARCHAR(100);
        END IF;
        
        -- Add user_role if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'user_role') THEN
            ALTER TABLE public.my_users ADD COLUMN user_role VARCHAR(20) DEFAULT 'employee';
        END IF;
        
        -- Add is_active if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'is_active') THEN
            ALTER TABLE public.my_users ADD COLUMN is_active BOOLEAN DEFAULT true;
        END IF;
        
        -- Add created_on if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'created_on') THEN
            ALTER TABLE public.my_users ADD COLUMN created_on TIMESTAMPTZ DEFAULT NOW();
        END IF;
        
        -- Add additional columns for extended functionality
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'work_location') THEN
            ALTER TABLE public.my_users ADD COLUMN work_location VARCHAR(255);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'shift_type') THEN
            ALTER TABLE public.my_users ADD COLUMN shift_type VARCHAR(50);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'supervisor_id') THEN
            ALTER TABLE public.my_users ADD COLUMN supervisor_id VARCHAR(50);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'salary_rate') THEN
            ALTER TABLE public.my_users ADD COLUMN salary_rate DECIMAL(10, 2);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'emergency_contact') THEN
            ALTER TABLE public.my_users ADD COLUMN emergency_contact VARCHAR(255);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'emergency_phone') THEN
            ALTER TABLE public.my_users ADD COLUMN emergency_phone VARCHAR(20);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'biometric_enabled') THEN
            ALTER TABLE public.my_users ADD COLUMN biometric_enabled BOOLEAN DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'preferred_language') THEN
            ALTER TABLE public.my_users ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'en';
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'notifications_enabled') THEN
            ALTER TABLE public.my_users ADD COLUMN notifications_enabled BOOLEAN DEFAULT true;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'total_coverage_given') THEN
            ALTER TABLE public.my_users ADD COLUMN total_coverage_given INTEGER DEFAULT 0;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'total_coverage_received') THEN
            ALTER TABLE public.my_users ADD COLUMN total_coverage_received INTEGER DEFAULT 0;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'attendance_rate') THEN
            ALTER TABLE public.my_users ADD COLUMN attendance_rate DECIMAL(5, 2) DEFAULT 0.0;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'leave_balance') THEN
            ALTER TABLE public.my_users ADD COLUMN leave_balance INTEGER DEFAULT 30;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_users' AND column_name = 'updated_at') THEN
            ALTER TABLE public.my_users ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        END IF;
    END IF;
END
$$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_my_users_email ON public.my_users(email);
CREATE INDEX IF NOT EXISTS idx_my_users_employee_id ON public.my_users(employee_id);
CREATE INDEX IF NOT EXISTS idx_my_users_department ON public.my_users(department);
CREATE INDEX IF NOT EXISTS idx_my_users_user_role ON public.my_users(user_role);
CREATE INDEX IF NOT EXISTS idx_my_users_is_active ON public.my_users(is_active);

-- Enable Row Level Security (RLS) - IMPORTANT for Supabase
ALTER TABLE public.my_users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Policy to allow users to read their own data
CREATE POLICY "Users can view own profile" ON public.my_users
    FOR SELECT USING (auth.uid() = id);

-- Policy to allow users to update their own data
CREATE POLICY "Users can update own profile" ON public.my_users
    FOR UPDATE USING (auth.uid() = id);

-- Policy to allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile" ON public.my_users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy for admins to manage all users (optional)
CREATE POLICY "Admins can manage all users" ON public.my_users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'ceo')
        )
    );

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

-- Grant necessary permissions
GRANT ALL ON public.my_users TO authenticated;
GRANT ALL ON public.my_users TO service_role;

-- Display table structure for verification
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'my_users'
ORDER BY ordinal_position;
