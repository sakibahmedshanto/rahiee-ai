-- Migration: Add Uniform Verification Columns to Attendance Table
-- Date: 2025-10-05
-- Purpose: Enable photo-based uniform verification during check-in

-- Add check-in photo columns
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_photo_url TEXT;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_photo_path TEXT;

-- Add uniform verification result columns
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS wearing_uniform BOOLEAN DEFAULT NULL;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS uniform_confidence NUMERIC(5,2) DEFAULT NULL;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS uniform_detection_data JSONB DEFAULT NULL;

-- Add verification tracking columns
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS photo_verified_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS verification_attempts INTEGER DEFAULT 0;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS manual_override BOOLEAN DEFAULT FALSE;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS override_reason TEXT DEFAULT NULL;

-- Optional: Add check-out photo columns (for future use)
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_out_photo_url TEXT;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_out_photo_path TEXT;

-- Add comments for documentation
COMMENT ON COLUMN attendance.check_in_photo_url IS 'Public URL of check-in photo from Supabase Storage';
COMMENT ON COLUMN attendance.check_in_photo_path IS 'Storage path: attendance-photos/checkin/{user_id}/{attendance_id}.jpg';
COMMENT ON COLUMN attendance.wearing_uniform IS 'AI detection result: true if uniform detected, false if not, null if not verified';
COMMENT ON COLUMN attendance.uniform_confidence IS 'AI confidence score from 0.00 to 100.00';
COMMENT ON COLUMN attendance.uniform_detection_data IS 'Full AI response from Google Vision API for debugging';
COMMENT ON COLUMN attendance.photo_verified_at IS 'Timestamp when photo was verified by AI';
COMMENT ON COLUMN attendance.verification_attempts IS 'Number of photo capture attempts before successful check-in';
COMMENT ON COLUMN attendance.manual_override IS 'True if employee checked in without uniform (with warning)';
COMMENT ON COLUMN attendance.override_reason IS 'Reason for manual override (e.g., "Uniform not detected but continued")';

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_attendance_uniform_verification 
ON attendance(wearing_uniform, uniform_confidence) 
WHERE wearing_uniform IS NOT NULL;

-- Create index for photo URLs
CREATE INDEX IF NOT EXISTS idx_attendance_photos 
ON attendance(check_in_photo_url) 
WHERE check_in_photo_url IS NOT NULL;

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'attendance' 
  AND column_name IN (
    'check_in_photo_url',
    'check_in_photo_path',
    'wearing_uniform',
    'uniform_confidence',
    'uniform_detection_data',
    'photo_verified_at',
    'verification_attempts',
    'manual_override'
  )
ORDER BY ordinal_position;




