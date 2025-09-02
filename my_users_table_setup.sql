-- My Users Table Setup for Rahiee AI
-- This creates the main users table for the Flutter app with Supabase
-- Run this script in your Supabase SQL Editor

-- Drop existing table if it exists
DROP TABLE IF EXISTS public.my_users CASCADE;

-- Create my_users table
CREATE TABLE IF NOT EXISTS public.my_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    profile_picture_url TEXT,
    department VARCHAR(100),
    position VARCHAR(100),
    employee_id VARCHAR(50) UNIQUE,
    hire_date DATE,
    salary DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
    address TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    blood_type VARCHAR(5),
    medical_conditions TEXT,
    skills TEXT[], -- Array of skills
    certifications JSONB, -- JSON for certifications with dates
    preferences JSONB, -- User preferences like notifications, theme, etc.
    last_login TIMESTAMPTZ,
    is_verified BOOLEAN DEFAULT false,
    verification_token VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMPTZ,
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(255),
    login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CREATE INDEXES FOR BETTER PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_my_users_email ON public.my_users(email);
CREATE INDEX IF NOT EXISTS idx_my_users_employee_id ON public.my_users(employee_id);
CREATE INDEX IF NOT EXISTS idx_my_users_department ON public.my_users(department);
CREATE INDEX IF NOT EXISTS idx_my_users_role ON public.my_users(role);
CREATE INDEX IF NOT EXISTS idx_my_users_status ON public.my_users(status);
CREATE INDEX IF NOT EXISTS idx_my_users_full_name ON public.my_users(full_name);
CREATE INDEX IF NOT EXISTS idx_my_users_hire_date ON public.my_users(hire_date);
CREATE INDEX IF NOT EXISTS idx_my_users_last_login ON public.my_users(last_login);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.my_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Users can view own profile" ON public.my_users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.my_users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.my_users;
DROP POLICY IF EXISTS "Admins can manage all users" ON public.my_users;
DROP POLICY IF EXISTS "Service role full access" ON public.my_users;
DROP POLICY IF EXISTS "Public can insert during signup" ON public.my_users;

-- RLS POLICIES FOR MY_USERS TABLE
CREATE POLICY "Users can view own profile" ON public.my_users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.my_users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.my_users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.my_users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Admins can manage all users" ON public.my_users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.my_users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Service role full access" ON public.my_users
    FOR ALL USING (auth.role() = 'service_role');

-- Allow authenticated users to insert their own profile during signup
CREATE POLICY "Authenticated users can insert own profile" ON public.my_users
    FOR INSERT WITH CHECK (auth.uid() = id AND auth.role() = 'authenticated');

-- GRANT PERMISSIONS
GRANT ALL ON public.my_users TO authenticated;
GRANT SELECT ON public.my_users TO anon;

-- CREATE FUNCTIONS FOR USER MANAGEMENT

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update timestamps
CREATE TRIGGER update_my_users_updated_at BEFORE UPDATE ON public.my_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate employee ID
CREATE OR REPLACE FUNCTION generate_employee_id()
RETURNS VARCHAR AS $$
DECLARE
    new_id VARCHAR;
    counter INTEGER := 1;
BEGIN
    LOOP
        new_id := 'EMP' || LPAD(counter::TEXT, 4, '0');
        
        IF NOT EXISTS (SELECT 1 FROM public.my_users WHERE employee_id = new_id) THEN
            RETURN new_id;
        END IF;
        
        counter := counter + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create user profile
CREATE OR REPLACE FUNCTION create_user_profile(
    p_email VARCHAR,
    p_full_name VARCHAR,
    p_phone_number VARCHAR DEFAULT NULL,
    p_department VARCHAR DEFAULT NULL,
    p_position VARCHAR DEFAULT NULL,
    p_role VARCHAR DEFAULT 'user'
)
RETURNS UUID AS $$
DECLARE
    new_user_id UUID;
    new_employee_id VARCHAR;
BEGIN
    -- Generate employee ID
    new_employee_id := generate_employee_id();
    
    -- Insert new user
    INSERT INTO public.my_users (
        email, 
        full_name, 
        phone_number, 
        department, 
        position, 
        employee_id, 
        role,
        hire_date
    ) VALUES (
        p_email, 
        p_full_name, 
        p_phone_number, 
        p_department, 
        p_position, 
        new_employee_id, 
        p_role,
        CURRENT_DATE
    ) RETURNING id INTO new_user_id;
    
    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user by email
CREATE OR REPLACE FUNCTION get_user_by_email(p_email VARCHAR)
RETURNS TABLE (
    user_id UUID,
    email VARCHAR,
    full_name VARCHAR,
    phone_number VARCHAR,
    department VARCHAR,
    position VARCHAR,
    employee_id VARCHAR,
    role VARCHAR,
    status VARCHAR,
    profile_picture_url TEXT,
    hire_date DATE,
    last_login TIMESTAMPTZ,
    is_verified BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email,
        u.full_name,
        u.phone_number,
        u.department,
        u.position,
        u.employee_id,
        u.role,
        u.status,
        u.profile_picture_url,
        u.hire_date,
        u.last_login,
        u.is_verified
    FROM public.my_users u
    WHERE u.email = p_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update last login
CREATE OR REPLACE FUNCTION update_last_login(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.my_users 
    SET last_login = NOW(),
        login_attempts = 0,
        account_locked_until = NULL
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment login attempts
CREATE OR REPLACE FUNCTION increment_login_attempts(p_email VARCHAR)
RETURNS VOID AS $$
DECLARE
    current_attempts INTEGER;
BEGIN
    UPDATE public.my_users 
    SET login_attempts = login_attempts + 1
    WHERE email = p_email
    RETURNING login_attempts INTO current_attempts;
    
    -- Lock account if too many attempts
    IF current_attempts >= 5 THEN
        UPDATE public.my_users 
        SET account_locked_until = NOW() + INTERVAL '30 minutes'
        WHERE email = p_email;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get users by department
CREATE OR REPLACE FUNCTION get_users_by_department(p_department VARCHAR)
RETURNS TABLE (
    user_id UUID,
    full_name VARCHAR,
    email VARCHAR,
    position VARCHAR,
    employee_id VARCHAR,
    hire_date DATE,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.full_name,
        u.email,
        u.position,
        u.employee_id,
        u.hire_date,
        u.status
    FROM public.my_users u
    WHERE u.department = p_department
    AND u.status = 'active'
    ORDER BY u.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search users
CREATE OR REPLACE FUNCTION search_users(p_search_term VARCHAR)
RETURNS TABLE (
    user_id UUID,
    full_name VARCHAR,
    email VARCHAR,
    department VARCHAR,
    position VARCHAR,
    employee_id VARCHAR,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.full_name,
        u.email,
        u.department,
        u.position,
        u.employee_id,
        u.status
    FROM public.my_users u
    WHERE (
        u.full_name ILIKE '%' || p_search_term || '%' OR
        u.email ILIKE '%' || p_search_term || '%' OR
        u.employee_id ILIKE '%' || p_search_term || '%' OR
        u.department ILIKE '%' || p_search_term || '%' OR
        u.position ILIKE '%' || p_search_term || '%'
    )
    AND u.status = 'active'
    ORDER BY u.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert default admin user (update credentials as needed)
INSERT INTO public.my_users (
    email, 
    full_name, 
    role, 
    employee_id, 
    department, 
    position, 
    hire_date, 
    is_verified
) VALUES (
    'admin@rahiee.ai', 
    'System Administrator', 
    'super_admin', 
    'EMP0001', 
    'IT', 
    'System Administrator', 
    CURRENT_DATE, 
    true
) ON CONFLICT (email) DO NOTHING;

-- Create a view for user summary (without sensitive data)
CREATE OR REPLACE VIEW user_summary AS
SELECT 
    id,
    email,
    full_name,
    department,
    position,
    employee_id,
    role,
    status,
    hire_date,
    last_login,
    is_verified
FROM public.my_users;

-- Grant access to the view
GRANT SELECT ON user_summary TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'My Users table setup completed successfully!';
    RAISE NOTICE 'Default admin user created: admin@rahiee.ai (update credentials as needed)';
    RAISE NOTICE 'Table includes RLS policies, indexes, and utility functions';
END $$;
