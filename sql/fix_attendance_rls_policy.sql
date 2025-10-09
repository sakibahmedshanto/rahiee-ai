-- Fix: Add RLS policy to allow employees to view their own attendance
-- Date: 2025-10-02
-- Issue: Employees couldn't view their attendance history due to missing RLS policy

-- Create policy allowing users to read their own attendance records
CREATE POLICY IF NOT EXISTS "Users can view own attendance"
ON attendance FOR SELECT
USING (auth.uid() = user_id);

-- Verify RLS is enabled on attendance table (should already be true)
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Check all policies on attendance table
SELECT 
  tablename,
  policyname, 
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'attendance'
ORDER BY policyname;





