# 🚨 CORRECTED SUPABASE MIGRATION GUIDE

## ⚠️ **CRITICAL FIXES APPLIED**

The original migration guide had **WRONG TABLE NAMES** that don't match the actual code. This corrected version uses the **ACTUAL TABLE NAMES** used in the application.

## 🗄️ **CORRECTED DATABASE SETUP**

### **Step 1: Create Users Table (CORRECTED NAME)**
```sql
-- ✅ CORRECT: Create my_users table (not 'users')
CREATE TABLE my_users (
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
CREATE INDEX idx_my_users_email ON my_users(email);
CREATE INDEX idx_my_users_employee_id ON my_users(employee_id);
CREATE INDEX idx_my_users_department ON my_users(department);
CREATE INDEX idx_my_users_is_active ON my_users(is_active);
```

### **Step 2: Create Schedules Table (CORRECTED NAME)**
```sql
-- ✅ CORRECT: Create employee_schedules table (not 'schedules')
CREATE TABLE employee_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  start_date_time TIMESTAMPTZ NOT NULL,
  end_date_time TIMESTAMPTZ NOT NULL,
  created_by_admin_id UUID REFERENCES my_users(id),
  assigned_user_id UUID REFERENCES my_users(id),
  actual_user_id UUID REFERENCES my_users(id),
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
CREATE INDEX idx_employee_schedules_start_date_time ON employee_schedules(start_date_time);
CREATE INDEX idx_employee_schedules_assigned_user_id ON employee_schedules(assigned_user_id);
CREATE INDEX idx_employee_schedules_department ON employee_schedules(department);
CREATE INDEX idx_employee_schedules_status ON employee_schedules(status);
CREATE INDEX idx_employee_schedules_is_active ON employee_schedules(is_active);

-- Composite index for schedule queries
CREATE INDEX idx_employee_schedules_date_status_active ON employee_schedules(start_date_time, status, is_active);
```

### **Step 3: Create Attendance Table**
```sql
-- ✅ CORRECT: Create attendance table
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES my_users(id),
  schedule_id UUID REFERENCES employee_schedules(id),
  date DATE NOT NULL,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  status VARCHAR DEFAULT 'pending',
  total_work_hours NUMERIC,
  overtime_hours NUMERIC,
  net_work_hours NUMERIC,
  reviewed_by UUID REFERENCES my_users(id),
  payment_status VARCHAR DEFAULT 'unpaid',
  latitude DECIMAL,
  longitude DECIMAL,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_schedule_id ON attendance(schedule_id);
CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_attendance_status ON attendance(status);
```

### **Step 4: Create Schedule Exchange Table (MISSING FROM ORIGINAL)**
```sql
-- ✅ NEW: Create schedule_exchange_requests table (was completely missing!)
CREATE TABLE schedule_exchange_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_user_id UUID NOT NULL REFERENCES my_users(id),
  requested_user_id UUID NOT NULL REFERENCES my_users(id),
  schedule_id UUID NOT NULL REFERENCES employee_schedules(id),
  request_reason TEXT,
  request_notes TEXT,
  request_type TEXT NOT NULL DEFAULT 'exchange',
  status TEXT NOT NULL DEFAULT 'pending',
  admin_id UUID REFERENCES my_users(id),
  admin_notes TEXT,
  rejection_reason TEXT,
  cancellation_reason TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMP,
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'expired')),
  CONSTRAINT valid_request_type CHECK (request_type IN ('exchange', 'swap', 'coverage'))
);

-- Create indexes for better performance
CREATE INDEX idx_schedule_exchange_requests_requester ON schedule_exchange_requests(requester_user_id);
CREATE INDEX idx_schedule_exchange_requests_requested ON schedule_exchange_requests(requested_user_id);
CREATE INDEX idx_schedule_exchange_requests_schedule ON schedule_exchange_requests(schedule_id);
CREATE INDEX idx_schedule_exchange_requests_status ON schedule_exchange_requests(status);
CREATE INDEX idx_schedule_exchange_requests_created ON schedule_exchange_requests(created_at);
```

### **Step 5: Enable Row Level Security (RLS)**
```sql
-- Enable RLS on my_users table
ALTER TABLE my_users ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON my_users
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own profile" ON my_users
  FOR UPDATE USING (auth.uid() = id);

-- Admins can read all users
CREATE POLICY "Admins can view all users" ON my_users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM my_users 
      WHERE id = auth.uid() 
      AND user_role IN ('admin', 'super_admin')
    )
  );

-- Enable RLS on employee_schedules table
ALTER TABLE employee_schedules ENABLE ROW LEVEL SECURITY;

-- Users can view schedules assigned to them
CREATE POLICY "Users can view assigned schedules" ON employee_schedules
  FOR SELECT USING (assigned_user_id = auth.uid());

-- Admins can view all schedules
CREATE POLICY "Admins can view all schedules" ON employee_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM my_users 
      WHERE id = auth.uid() 
      AND user_role IN ('admin', 'super_admin')
    )
  );

-- Enable RLS on attendance table
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Users can view their own attendance
CREATE POLICY "Users can view own attendance" ON attendance
  FOR SELECT USING (user_id = auth.uid());

-- Enable RLS on schedule_exchange_requests table
ALTER TABLE schedule_exchange_requests ENABLE ROW LEVEL SECURITY;

-- Policy for users to see their own requests
CREATE POLICY "Users can view their own exchange requests" ON schedule_exchange_requests
    FOR SELECT USING (
        requester_user_id = auth.uid() OR 
        requested_user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );

-- Policy for users to create their own requests
CREATE POLICY "Users can create exchange requests" ON schedule_exchange_requests
    FOR INSERT WITH CHECK (requester_user_id = auth.uid());

-- Policy for admins to update requests
CREATE POLICY "Admins can update exchange requests" ON schedule_exchange_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );
```

### **Step 6: Create Exchange Functions**
```sql
-- Run the complete exchange functions from /sql/schedule_exchange_functions.sql
-- This includes all the RPC functions needed for the exchange system
```

## 🔍 **VERIFICATION QUERIES**

After running the migration, verify with these queries:

```sql
-- Check if all tables exist with correct names
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('my_users', 'employee_schedules', 'attendance', 'schedule_exchange_requests');

-- Check if exchange functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%schedule_exchange%';

-- Test table relationships
SELECT 
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public';
```

## ⚠️ **CRITICAL DIFFERENCES FROM ORIGINAL**

1. **Table Names Fixed:**
   - ❌ `users` → ✅ `my_users`
   - ❌ `schedules` → ✅ `employee_schedules`

2. **Added Missing Table:**
   - ✅ `schedule_exchange_requests` (was completely missing!)

3. **Added Missing RLS Policies:**
   - ✅ Exchange request policies

4. **Added Missing Functions:**
   - ✅ All schedule exchange RPC functions

## 🚀 **NEXT STEPS**

1. **Run this corrected migration** in Supabase
2. **Run the exchange functions** from `/sql/schedule_exchange_functions.sql`
3. **Test the exchange system** thoroughly
4. **Update all documentation** to reflect correct table names

This corrected migration should resolve all the database inconsistencies!
