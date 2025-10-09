-- Auto-create schedule assignment when a schedule is created
-- This prevents the issue where schedules have assigned_user_id but no entry in schedule_assignments
-- Date: October 5, 2025

-- Function to auto-create assignment
CREATE OR REPLACE FUNCTION auto_create_schedule_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only create assignment if assigned_user_id is set and no assignment exists
    IF NEW.assigned_user_id IS NOT NULL THEN
        -- Check if assignment already exists
        IF NOT EXISTS (
            SELECT 1 
            FROM public.schedule_assignments 
            WHERE schedule_id = NEW.id 
              AND user_id = NEW.assigned_user_id
              AND is_active = true
        ) THEN
            -- Create the assignment
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
            ) VALUES (
                NEW.id,
                NEW.assigned_user_id,
                NEW.created_by_admin_id,
                'active',
                true,
                'Auto-created from assigned_user_id',
                NOW(),
                NOW(),
                NOW()
            );
            
            -- Update current_participants
            NEW.current_participants := COALESCE(NEW.current_participants, 0) + 1;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for INSERT
DROP TRIGGER IF EXISTS trigger_auto_create_assignment_on_insert ON public.employee_schedules;
CREATE TRIGGER trigger_auto_create_assignment_on_insert
    AFTER INSERT ON public.employee_schedules
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_schedule_assignment();

-- Create trigger for UPDATE (when assigned_user_id changes)
DROP TRIGGER IF EXISTS trigger_auto_create_assignment_on_update ON public.employee_schedules;
CREATE TRIGGER trigger_auto_create_assignment_on_update
    AFTER UPDATE OF assigned_user_id ON public.employee_schedules
    FOR EACH ROW
    WHEN (OLD.assigned_user_id IS DISTINCT FROM NEW.assigned_user_id AND NEW.assigned_user_id IS NOT NULL)
    EXECUTE FUNCTION auto_create_schedule_assignment();

-- Verification
-- Test by creating a new schedule
/*
INSERT INTO public.employee_schedules (
    title,
    description,
    start_date_time,
    end_date_time,
    created_by_admin_id,
    assigned_user_id,
    department,
    location,
    status
) VALUES (
    'Test Auto Assignment',
    'Testing trigger',
    NOW() + INTERVAL '1 day',
    NOW() + INTERVAL '1 day' + INTERVAL '4 hours',
    'efc29a10-b695-4acd-9307-61ee8acce6bb', -- admin user
    '883d252d-83d7-4ce5-a1ef-f34e76f5189d', -- employee user (shantoo)
    'IT',
    'Office',
    'active'
);

-- Check if assignment was auto-created
SELECT 
    es.title,
    es.current_participants,
    sa.user_id,
    sa.notes,
    u.full_name
FROM public.employee_schedules es
JOIN public.schedule_assignments sa ON es.id = sa.schedule_id
JOIN public.my_users u ON sa.user_id = u.id
WHERE es.title = 'Test Auto Assignment';
*/




