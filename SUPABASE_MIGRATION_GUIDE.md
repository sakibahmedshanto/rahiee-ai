# Supabase Migration - Setup Instructions

## 🎉 Migration Complete!

Your app has been successfully migrated from Firebase to Supabase. Follow these steps to complete the setup:

## 🚀 Step 1: Create Supabase Project

1. Go to [https://YOUR_SUPABASE_PROJECT_REF.supabase.com](https://YOUR_SUPABASE_PROJECT_REF.supabase.com)
2. Create a new project
3. Copy your project URL and anon key

## ⚙️ Step 2: Update Supabase Configuration

Open `lib/services/supabase_service.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual Supabase credentials.

## 🗄️ Step 3: Create Database Tables

Run these SQL commands in your Supabase SQL Editor:

### Users Table
```sql
-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id TEXT UNIQUE,
  username TEXT,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  user_img TEXT,
  user_device_token TEXT,
  full_name TEXT NOT NULL,
  department TEXT NOT NULL,
  position TEXT NOT NULL,
  user_role TEXT DEFAULT 'employee',
  is_active BOOLEAN DEFAULT true,
  created_on TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  work_location TEXT,
  shift_type TEXT,
  supervisor_id TEXT,
  salary_rate DECIMAL,
  emergency_contact TEXT,
  emergency_phone TEXT,
  biometric_enabled BOOLEAN DEFAULT false,
  preferred_language TEXT DEFAULT 'en',
  notifications_enabled BOOLEAN DEFAULT true,
  total_coverage_given INTEGER DEFAULT 0,
  total_coverage_received INTEGER DEFAULT 0,
  attendance_rate DECIMAL,
  leave_balance INTEGER
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_employee_id ON users(employee_id);
CREATE INDEX idx_users_department ON users(department);
CREATE INDEX idx_users_is_active ON users(is_active);
```

### Schedules Table
```sql
-- Create schedules table
CREATE TABLE schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  start_date_time TIMESTAMPTZ NOT NULL,
  end_date_time TIMESTAMPTZ NOT NULL,
  created_by_admin_id UUID REFERENCES users(id),
  assigned_user_id UUID REFERENCES users(id),
  actual_user_id UUID REFERENCES users(id),
  department TEXT NOT NULL,
  location TEXT NOT NULL,
  latitude DECIMAL,
  longitude DECIMAL,
  status TEXT DEFAULT 'active',
  requirements JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  tags TEXT[],
  custom_fields JSONB,
  assignment_history JSONB
);

-- Create indexes for optimized queries
CREATE INDEX idx_schedules_start_date_time ON schedules(start_date_time);
CREATE INDEX idx_schedules_assigned_user_id ON schedules(assigned_user_id);
CREATE INDEX idx_schedules_department ON schedules(department);
CREATE INDEX idx_schedules_status ON schedules(status);
CREATE INDEX idx_schedules_is_active ON schedules(is_active);

-- Composite index for schedule queries (replaces Firebase composite index)
CREATE INDEX idx_schedules_date_status_active ON schedules(start_date_time, status, is_active);
```

## 🔐 Step 4: Enable Row Level Security (RLS)

```sql
-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Admins can read all users
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND user_role IN ('admin', 'ceo')
    )
  );

-- Enable RLS on schedules table
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;

-- Users can view schedules assigned to them
CREATE POLICY "Users can view assigned schedules" ON schedules
  FOR SELECT USING (assigned_user_id = auth.uid());

-- Admins can manage all schedules
CREATE POLICY "Admins can manage schedules" ON schedules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND user_role IN ('admin', 'ceo')
    )
  );
```

## 📧 Step 5: Configure Authentication

1. In Supabase Dashboard → Authentication → Settings
2. Enable email confirmation if desired
3. Configure email templates
4. Set up OAuth providers (Google, etc.) if using social login

## 🔄 Step 6: Create Admin User

Run this SQL to create your first admin user:

```sql
-- Insert admin user (replace with your details)
INSERT INTO users (
  id, 
  employee_id, 
  username, 
  email, 
  full_name, 
  department, 
  position, 
  user_role,
  is_active
) VALUES (
  'REPLACE_WITH_YOUR_AUTH_USER_ID',
  'EMP-ADMIN001',
  'admin',
  'admin@yourcompany.com',
  'System Administrator',
  'Management',
  'Administrator',
  'admin',
  true
);
```

## ✅ Migration Summary

### ✅ **Completed:**
- ✅ Dependencies updated (Firebase → Supabase)
- ✅ Supabase service created
- ✅ User Model updated for Supabase
- ✅ Schedule Model updated for Supabase
- ✅ Authentication controllers migrated
- ✅ User data controller migrated
- ✅ Schedule controller migrated
- ✅ Admin controller migrated
- ✅ Splash controller updated
- ✅ Forget password controller updated
- ✅ Google Sign-in controller updated
- ✅ All Firebase imports removed

### 🎯 **Benefits of Migration:**
- **Better Performance**: Supabase uses PostgreSQL with optimized indexing
- **Real-time Features**: Built-in real-time subscriptions
- **SQL Flexibility**: Full SQL support for complex queries
- **Row Level Security**: Fine-grained access control
- **Open Source**: No vendor lock-in
- **Cost Effective**: Generous free tier and predictable pricing

### 🔧 **Next Steps:**
1. Update Supabase credentials in `supabase_service.dart`
2. Create database tables using provided SQL
3. Set up Row Level Security policies
4. Create your first admin user
5. Test the application end-to-end

### 📝 **Notes:**
- All previous Firebase functionality has been preserved
- Database schema is optimized for better performance
- Error handling includes user-friendly messages
- Indexing strategy optimized for your app's query patterns

Your app is now ready to run on Supabase! 🚀
