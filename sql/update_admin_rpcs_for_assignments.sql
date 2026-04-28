-- ============================================================================
-- UPDATE ADMIN RPC FUNCTIONS FOR ASSIGNMENT-BASED ARCHITECTURE
-- ============================================================================
-- This script updates admin RPC functions to work with schedule_assignments
-- instead of the removed assigned_user_id column
-- ============================================================================

-- ============================================================================
-- 1. Update admin_get_schedules to join with schedule_assignments
-- ============================================================================
CREATE OR REPLACE FUNCTION public.admin_get_schedules(
    p_admin_id uuid,
    p_start_date date DEFAULT NULL,
    p_end_date date DEFAULT NULL,
    p_department varchar DEFAULT NULL,
    p_status varchar DEFAULT NULL,
    p_assigned_user_id uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role VARCHAR;
    v_schedules JSON;
BEGIN
    -- Verify admin has permission
    SELECT user_role INTO v_admin_role FROM my_users WHERE id = p_admin_id AND is_active = true;
    IF v_admin_role IS NULL OR v_admin_role NOT IN ('admin', 'ceo', 'manager') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: Only active admins can view schedules'
        );
    END IF;

    -- Get schedules with assignments
    WITH schedule_data AS (
        SELECT DISTINCT ON (es.id)
            es.id,
            es.title,
            es.description,
            es.start_date_time,
            es.end_date_time,
            es.department,
            es.location,
            es.latitude,
            es.longitude,
            es.status,
            es.requirements,
            es.notes,
            es.tags,
            es.custom_fields,
            es.is_active,
            es.is_multi_user,
            es.max_participants,
            es.min_participants,
            es.current_participants,
            es.created_at,
            es.updated_at,
            es.created_by_admin_id,
            -- Get all assigned users as JSON array
            (
                SELECT json_agg(
                    json_build_object(
                        'id', u.id,
                        'employee_id', u.employee_id,
                        'full_name', u.full_name,
                        'email', u.email,
                        'department', u.department,
                        'user_role', u.user_role,
                        'assigned_at', sa.assigned_at,
                        'assignment_notes', sa.notes
                    )
                )
                FROM schedule_assignments sa
                JOIN my_users u ON sa.user_id = u.id
                WHERE sa.schedule_id = es.id
                AND sa.is_active = true
                AND sa.status = 'active'
            ) as assigned_users,
            json_build_object(
                'id', ca.id,
                'employee_id', ca.employee_id,
                'full_name', ca.full_name,
                'email', ca.email
            ) as created_by_admin
        FROM employee_schedules es
        JOIN my_users ca ON es.created_by_admin_id = ca.id
        LEFT JOIN schedule_assignments sa ON es.id = sa.schedule_id 
            AND sa.is_active = true 
            AND sa.status = 'active'
        WHERE 1=1
        AND (p_start_date IS NULL OR DATE(es.start_date_time) >= p_start_date)
        AND (p_end_date IS NULL OR DATE(es.end_date_time) <= p_end_date)
        AND (p_department IS NULL OR es.department ILIKE '%' || p_department || '%')
        AND (p_status IS NULL OR es.status = p_status)
        AND (p_assigned_user_id IS NULL OR sa.user_id = p_assigned_user_id)
        ORDER BY es.id, es.start_date_time DESC
    )
    SELECT json_agg(
        json_build_object(
            'schedule_id', sd.id,
            'title', sd.title,
            'description', sd.description,
            'start_date_time', sd.start_date_time,
            'end_date_time', sd.end_date_time,
            'department', sd.department,
            'location', sd.location,
            'latitude', sd.latitude,
            'longitude', sd.longitude,
            'status', sd.status,
            'requirements', sd.requirements,
            'notes', sd.notes,
            'tags', sd.tags,
            'custom_fields', sd.custom_fields,
            'is_active', sd.is_active,
            'is_multi_user', sd.is_multi_user,
            'max_participants', sd.max_participants,
            'min_participants', sd.min_participants,
            'current_participants', sd.current_participants,
            'created_at', sd.created_at,
            'updated_at', sd.updated_at,
            'assigned_users', COALESCE(sd.assigned_users, '[]'::json),
            'created_by_admin', sd.created_by_admin
        )
    ) INTO v_schedules
    FROM schedule_data sd;

    RETURN json_build_object(
        'success', true,
        'schedules', COALESCE(v_schedules, '[]'::json),
        'total_count', (SELECT COUNT(DISTINCT es.id) 
                       FROM employee_schedules es
                       LEFT JOIN schedule_assignments sa ON es.id = sa.schedule_id 
                           AND sa.is_active = true 
                           AND sa.status = 'active'
                       WHERE 1=1
                       AND (p_start_date IS NULL OR DATE(es.start_date_time) >= p_start_date)
                       AND (p_end_date IS NULL OR DATE(es.end_date_time) <= p_end_date)
                       AND (p_department IS NULL OR es.department ILIKE '%' || p_department || '%')
                       AND (p_status IS NULL OR es.status = p_status)
                       AND (p_assigned_user_id IS NULL OR sa.user_id = p_assigned_user_id))
    );

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to fetch schedules: ' || SQLERRM
    );
END;
$$;

-- ============================================================================
-- 2. Update admin_update_schedule to work without assigned_user_id
-- ============================================================================
CREATE OR REPLACE FUNCTION public.admin_update_schedule(
    p_admin_id uuid,
    p_schedule_id uuid,
    p_title varchar DEFAULT NULL,
    p_description text DEFAULT NULL,
    p_start_date_time timestamptz DEFAULT NULL,
    p_end_date_time timestamptz DEFAULT NULL,
    p_department varchar DEFAULT NULL,
    p_location varchar DEFAULT NULL,
    p_latitude numeric DEFAULT NULL,
    p_longitude numeric DEFAULT NULL,
    p_status varchar DEFAULT NULL,
    p_requirements jsonb DEFAULT NULL,
    p_notes text DEFAULT NULL,
    p_tags text[] DEFAULT NULL,
    p_custom_fields jsonb DEFAULT NULL,
    p_is_multi_user boolean DEFAULT NULL,
    p_max_participants integer DEFAULT NULL,
    p_min_participants integer DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role VARCHAR;
    v_schedule_exists BOOLEAN;
    v_conflict_count INTEGER;
    v_current_start TIMESTAMPTZ;
    v_current_end TIMESTAMPTZ;
BEGIN
    -- Verify admin has permission
    SELECT user_role INTO v_admin_role FROM my_users WHERE id = p_admin_id AND is_active = true;
    IF v_admin_role IS NULL OR v_admin_role NOT IN ('admin', 'ceo', 'manager') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: Only active admins can update schedules'
        );
    END IF;

    -- Check if schedule exists
    SELECT EXISTS(SELECT 1 FROM employee_schedules WHERE id = p_schedule_id),
           start_date_time, end_date_time
    INTO v_schedule_exists, v_current_start, v_current_end
    FROM employee_schedules WHERE id = p_schedule_id;
    
    IF NOT v_schedule_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schedule not found'
        );
    END IF;

    -- Validate date range if being updated
    IF p_start_date_time IS NOT NULL AND p_end_date_time IS NOT NULL THEN
        IF p_start_date_time >= p_end_date_time THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Start time must be before end time'
            );
        END IF;
    END IF;

    -- Check for conflicts if time is being changed
    IF (p_start_date_time IS NOT NULL AND p_start_date_time != v_current_start) OR
       (p_end_date_time IS NOT NULL AND p_end_date_time != v_current_end) THEN
        
        -- Check conflicts for all currently assigned users
        SELECT COUNT(*) INTO v_conflict_count
        FROM schedule_assignments sa
        JOIN employee_schedules es ON sa.schedule_id = es.id
        WHERE sa.user_id IN (
            SELECT user_id FROM schedule_assignments 
            WHERE schedule_id = p_schedule_id 
            AND is_active = true 
            AND status = 'active'
        )
        AND sa.schedule_id != p_schedule_id
        AND sa.is_active = true
        AND sa.status = 'active'
        AND es.is_active = true
        AND es.status = 'active'
        AND (
            (es.start_date_time <= COALESCE(p_start_date_time, v_current_start) 
             AND es.end_date_time > COALESCE(p_start_date_time, v_current_start)) OR
            (es.start_date_time < COALESCE(p_end_date_time, v_current_end) 
             AND es.end_date_time >= COALESCE(p_end_date_time, v_current_end)) OR
            (es.start_date_time >= COALESCE(p_start_date_time, v_current_start) 
             AND es.end_date_time <= COALESCE(p_end_date_time, v_current_end))
        );

        IF v_conflict_count > 0 THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Schedule conflict detected for assigned users'
            );
        END IF;
    END IF;

    -- Update the schedule
    UPDATE employee_schedules SET
        title = COALESCE(p_title, title),
        description = COALESCE(p_description, description),
        start_date_time = COALESCE(p_start_date_time, start_date_time),
        end_date_time = COALESCE(p_end_date_time, end_date_time),
        department = COALESCE(p_department, department),
        location = COALESCE(p_location, location),
        latitude = COALESCE(p_latitude, latitude),
        longitude = COALESCE(p_longitude, longitude),
        status = COALESCE(p_status, status),
        requirements = COALESCE(p_requirements, requirements),
        notes = COALESCE(p_notes, notes),
        tags = COALESCE(p_tags, tags),
        custom_fields = COALESCE(p_custom_fields, custom_fields),
        is_multi_user = COALESCE(p_is_multi_user, is_multi_user),
        max_participants = COALESCE(p_max_participants, max_participants),
        min_participants = COALESCE(p_min_participants, min_participants),
        updated_at = NOW()
    WHERE id = p_schedule_id;

    RETURN json_build_object(
        'success', true,
        'message', 'Schedule updated successfully'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to update schedule: ' || SQLERRM
    );
END;
$$;

-- ============================================================================
-- 3. Update admin_get_available_users to check schedule_assignments
-- ============================================================================
CREATE OR REPLACE FUNCTION public.admin_get_available_users(
    p_admin_id uuid,
    p_start_date_time timestamptz DEFAULT NULL,
    p_end_date_time timestamptz DEFAULT NULL,
    p_department varchar DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role VARCHAR;
    v_users JSON;
BEGIN
    -- Verify admin has permission
    SELECT user_role INTO v_admin_role FROM my_users WHERE id = p_admin_id AND is_active = true;
    IF v_admin_role IS NULL OR v_admin_role NOT IN ('admin', 'ceo', 'manager') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: Only active admins can view users'
        );
    END IF;

    -- Get available users (not conflicting with given time range)
    WITH user_data AS (
        SELECT 
            u.id,
            u.employee_id,
            u.full_name,
            u.email,
            u.department,
            u.position,
            u.user_role,
            CASE 
                WHEN p_start_date_time IS NULL OR p_end_date_time IS NULL THEN true
                ELSE NOT EXISTS(
                    SELECT 1 
                    FROM schedule_assignments sa
                    JOIN employee_schedules es ON sa.schedule_id = es.id
                    WHERE sa.user_id = u.id
                    AND sa.is_active = true
                    AND sa.status = 'active'
                    AND es.is_active = true
                    AND es.status = 'active'
                    AND (
                        (es.start_date_time <= p_start_date_time AND es.end_date_time > p_start_date_time) OR
                        (es.start_date_time < p_end_date_time AND es.end_date_time >= p_end_date_time) OR
                        (es.start_date_time >= p_start_date_time AND es.end_date_time <= p_end_date_time)
                    )
                )
            END as is_available
        FROM my_users u
        WHERE u.is_active = true
        AND u.user_role != 'admin'
        AND (p_department IS NULL OR u.department ILIKE '%' || p_department || '%')
        ORDER BY u.full_name
    )
    SELECT json_agg(
        json_build_object(
            'id', ud.id,
            'employee_id', ud.employee_id,
            'full_name', ud.full_name,
            'email', ud.email,
            'department', ud.department,
            'position', ud.position,
            'user_role', ud.user_role,
            'is_available', ud.is_available
        )
    ) INTO v_users
    FROM user_data ud;

    RETURN json_build_object(
        'success', true,
        'users', COALESCE(v_users, '[]'::json)
    );

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to fetch users: ' || SQLERRM
    );
END;
$$;

-- ============================================================================
-- 4. Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION public.admin_get_schedules TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_update_schedule TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_get_available_users TO authenticated, service_role;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- ✅ Updated admin_get_schedules to use schedule_assignments
-- ✅ Updated admin_update_schedule to remove assigned_user_id parameter
-- ✅ Updated admin_get_available_users to check schedule_assignments
-- ✅ All functions now work with assignment-based architecture
-- ============================================================================




