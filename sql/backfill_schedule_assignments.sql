-- Backfill schedule_assignments for existing schedules
-- This migrates old schedules (with only assigned_user_id) to the new multi-user system
-- Date: October 5, 2025

-- Step 1: Insert missing assignments for schedules that have assigned_user_id but no assignments
INSERT INTO public.schedule_assignments (
    schedule_id,
    user_id,
    assigned_by_admin_id,
    status,
    is_active,
    notes,
    assigned_at,
    created_at,
    updated_at
)
SELECT 
    es.id as schedule_id,
    es.assigned_user_id as user_id,
    es.created_by_admin_id as assigned_by_admin_id,
    'active' as status,
    true as is_active,
    'Backfilled from assigned_user_id' as notes,
    es.created_at as assigned_at,
    NOW() as created_at,
    NOW() as updated_at
FROM public.employee_schedules es
WHERE es.assigned_user_id IS NOT NULL
  AND es.status != 'cancelled'
  AND NOT EXISTS (
      SELECT 1 
      FROM public.schedule_assignments sa 
      WHERE sa.schedule_id = es.id 
        AND sa.user_id = es.assigned_user_id
        AND sa.is_active = true
  );

-- Step 2: Update current_participants count for all schedules
UPDATE public.employee_schedules es
SET current_participants = (
    SELECT COUNT(*)
    FROM public.schedule_assignments sa
    WHERE sa.schedule_id = es.id
      AND sa.is_active = true
      AND sa.status = 'active'
)
WHERE es.id IN (
    SELECT DISTINCT schedule_id 
    FROM public.schedule_assignments
);

-- Step 3: Verification - Show backfilled assignments
SELECT 
    es.id,
    es.title,
    es.start_date_time,
    es.current_participants,
    u.full_name as assigned_to,
    sa.notes
FROM public.schedule_assignments sa
JOIN public.employee_schedules es ON sa.schedule_id = es.id
JOIN public.my_users u ON sa.user_id = u.id
WHERE sa.notes = 'Backfilled from assigned_user_id'
ORDER BY es.start_date_time DESC;




