-- Setup Storage Bucket and RLS Policies for Attendance Photos
-- Date: 2025-10-05
-- Bucket: attendance-photos

-- Note: Storage bucket needs to be created via Supabase Dashboard first
-- Go to: Storage → Create bucket → Name: "attendance-photos" → Public: false

-- =======================================================
-- RLS POLICIES FOR STORAGE BUCKET: attendance-photos
-- =======================================================

-- Policy 1: Users can upload their own check-in photos
CREATE POLICY IF NOT EXISTS "Users can upload own check-in photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'attendance-photos' 
  AND (storage.foldername(name))[1] = 'checkin'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Policy 2: Users can view their own photos
CREATE POLICY IF NOT EXISTS "Users can view own attendance photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'attendance-photos'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Policy 3: Users can update their own photos (for retries)
CREATE POLICY IF NOT EXISTS "Users can update own photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'attendance-photos'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Policy 4: Users can delete their own temp photos
CREATE POLICY IF NOT EXISTS "Users can delete own temp photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attendance-photos'
  AND (storage.foldername(name))[1] = 'temp'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Policy 5: Admins can view all photos
CREATE POLICY IF NOT EXISTS "Admins can view all attendance photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'attendance-photos'
  AND EXISTS (
    SELECT 1 FROM my_users
    WHERE id = auth.uid()
    AND user_role IN ('admin', 'ceo', 'manager')
    AND is_active = true
  )
);

-- Policy 6: Service role has full access (for Edge Functions)
CREATE POLICY IF NOT EXISTS "Service role full access to attendance photos"
ON storage.objects FOR ALL
TO service_role
USING (bucket_id = 'attendance-photos');

-- =======================================================
-- CLEANUP FUNCTION: Remove old temp photos
-- =======================================================

CREATE OR REPLACE FUNCTION cleanup_old_temp_photos()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete temp photos older than 1 hour
  DELETE FROM storage.objects
  WHERE bucket_id = 'attendance-photos'
    AND (storage.foldername(name))[1] = 'temp'
    AND created_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- Create a scheduled job to run cleanup (requires pg_cron extension)
-- Run this separately if pg_cron is enabled:
-- SELECT cron.schedule('cleanup-temp-photos', '0 * * * *', 'SELECT cleanup_old_temp_photos()');

COMMENT ON FUNCTION cleanup_old_temp_photos IS 'Removes temporary attendance photos older than 1 hour';

-- =======================================================
-- VERIFY SETUP
-- =======================================================

-- Check if policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'objects'
  AND policyname LIKE '%attendance%'
ORDER BY policyname;




