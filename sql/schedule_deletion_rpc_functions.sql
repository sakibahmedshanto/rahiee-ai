-- 🚀 SCALABLE SCHEDULE DELETION RPC FUNCTIONS
-- RPC-based approach for better scalability and security

-- =====================================================
-- RPC FUNCTION 1: Preview Schedule Deletion
-- =====================================================
CREATE OR REPLACE FUNCTION preview_schedule_deletion(
    p_hours_back INTEGER DEFAULT 24
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    schedule_count INTEGER;
    attendance_count INTEGER;
    exchange_count INTEGER;
    oldest_schedule TIMESTAMPTZ;
    newest_schedule TIMESTAMPTZ;
BEGIN
    -- Count schedules to be deleted
    SELECT COUNT(*) INTO schedule_count
    FROM employee_schedules 
    WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
    
    -- Count attendance records to be affected
    SELECT COUNT(*) INTO attendance_count
    FROM attendance a
    JOIN employee_schedules s ON a.schedule_id = s.id
    WHERE s.created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
    
    -- Count exchange requests to be affected
    SELECT COUNT(*) INTO exchange_count
    FROM schedule_exchange_requests ser
    JOIN employee_schedules s ON ser.schedule_id = s.id
    WHERE s.created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
    
    -- Get time range
    SELECT MIN(created_at), MAX(created_at) 
    INTO oldest_schedule, newest_schedule
    FROM employee_schedules 
    WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
    
    -- Build result
    result := json_build_object(
        'success', true,
        'preview_data', json_build_object(
            'hours_back', p_hours_back,
            'schedules_to_delete', schedule_count,
            'attendance_records_affected', attendance_count,
            'exchange_requests_affected', exchange_count,
            'oldest_schedule', oldest_schedule,
            'newest_schedule', newest_schedule,
            'deletion_timestamp', NOW()
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- =====================================================
-- RPC FUNCTION 2: Get Detailed Schedule List for Deletion
-- =====================================================
CREATE OR REPLACE FUNCTION get_schedules_for_deletion(
    p_hours_back INTEGER DEFAULT 24,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    schedules JSON;
BEGIN
    -- Get detailed schedule information
    SELECT json_agg(
        json_build_object(
            'id', s.id,
            'title', s.title,
            'start_date_time', s.start_date_time,
            'end_date_time', s.end_date_time,
            'created_at', s.created_at,
            'status', s.status,
            'is_active', s.is_active,
            'assigned_user_name', u.full_name,
            'assigned_user_id', u.employee_id,
            'created_by_admin', admin.full_name,
            'department', s.department,
            'location', s.location
        )
    ) INTO schedules
    FROM employee_schedules s
    LEFT JOIN my_users u ON s.assigned_user_id = u.id
    LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
    WHERE s.created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL
    ORDER BY s.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    -- Build result
    result := json_build_object(
        'success', true,
        'schedules', COALESCE(schedules, '[]'::json),
        'pagination', json_build_object(
            'limit', p_limit,
            'offset', p_offset,
            'has_more', EXISTS(
                SELECT 1 FROM employee_schedules 
                WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL
                OFFSET p_offset + p_limit
            )
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- =====================================================
-- RPC FUNCTION 3: Safe Schedule Deletion with Backup
-- =====================================================
CREATE OR REPLACE FUNCTION safe_delete_schedules(
    p_hours_back INTEGER DEFAULT 24,
    p_create_backup BOOLEAN DEFAULT true,
    p_executed_by TEXT DEFAULT 'system'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    schedule_count INTEGER;
    attendance_count INTEGER;
    exchange_count INTEGER;
    backup_count INTEGER;
BEGIN
    -- Start transaction
    BEGIN
        -- Count records before deletion
        SELECT COUNT(*) INTO schedule_count
        FROM employee_schedules 
        WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
        
        SELECT COUNT(*) INTO attendance_count
        FROM attendance a
        JOIN employee_schedules s ON a.schedule_id = s.id
        WHERE s.created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
        
        SELECT COUNT(*) INTO exchange_count
        FROM schedule_exchange_requests ser
        JOIN employee_schedules s ON ser.schedule_id = s.id
        WHERE s.created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
        
        -- Create backup if requested
        IF p_create_backup THEN
            -- Create backup table if it doesn't exist
            CREATE TABLE IF NOT EXISTS employee_schedules_deletion_backup (
                id UUID,
                title TEXT,
                description TEXT,
                start_date_time TIMESTAMPTZ,
                end_date_time TIMESTAMPTZ,
                created_by_admin_id UUID,
                assigned_user_id UUID,
                actual_user_id UUID,
                department TEXT,
                location TEXT,
                latitude DECIMAL,
                longitude DECIMAL,
                status TEXT,
                requirements JSONB,
                created_at TIMESTAMPTZ,
                updated_at TIMESTAMPTZ,
                notes TEXT,
                is_active BOOLEAN,
                tags TEXT[],
                custom_fields JSONB,
                assignment_history JSONB,
                deletion_timestamp TIMESTAMPTZ DEFAULT NOW(),
                deletion_reason TEXT,
                executed_by TEXT
            );
            
            -- Insert backup data
            INSERT INTO employee_schedules_deletion_backup
            SELECT 
                id, title, description, start_date_time, end_date_time,
                created_by_admin_id, assigned_user_id, actual_user_id,
                department, location, latitude, longitude, status,
                requirements, created_at, updated_at, notes, is_active,
                tags, custom_fields, assignment_history,
                NOW() as deletion_timestamp,
                'RPC_deletion_' || p_hours_back || '_hours' as deletion_reason,
                p_executed_by as executed_by
            FROM employee_schedules 
            WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
            
            GET DIAGNOSTICS backup_count = ROW_COUNT;
        END IF;
        
        -- Delete exchange requests first (foreign key constraint)
        DELETE FROM schedule_exchange_requests 
        WHERE schedule_id IN (
            SELECT id FROM employee_schedules 
            WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL
        );
        
        -- Delete attendance records second
        DELETE FROM attendance 
        WHERE schedule_id IN (
            SELECT id FROM employee_schedules 
            WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL
        );
        
        -- Delete schedules last
        DELETE FROM employee_schedules 
        WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL;
        
        -- Log the deletion
        INSERT INTO schedule_deletion_log (
            schedules_deleted,
            attendance_records_deleted,
            exchange_requests_deleted,
            deletion_reason,
            executed_by,
            success
        ) VALUES (
            schedule_count,
            attendance_count,
            exchange_count,
            'RPC_deletion_' || p_hours_back || '_hours',
            p_executed_by,
            true
        );
        
        -- Build success result
        result := json_build_object(
            'success', true,
            'deletion_summary', json_build_object(
                'schedules_deleted', schedule_count,
                'attendance_records_deleted', attendance_count,
                'exchange_requests_deleted', exchange_count,
                'backup_created', p_create_backup,
                'backup_records', backup_count,
                'hours_back', p_hours_back,
                'executed_by', p_executed_by,
                'deletion_timestamp', NOW()
            )
        );
        
        RETURN result;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error
            INSERT INTO schedule_deletion_log (
                schedules_deleted,
                attendance_records_deleted,
                exchange_requests_deleted,
                deletion_reason,
                executed_by,
                success,
                error_message
            ) VALUES (
                0, 0, 0,
                'RPC_deletion_' || p_hours_back || '_hours',
                p_executed_by,
                false,
                SQLERRM
            );
            
            -- Return error result
            RETURN json_build_object(
                'success', false,
                'error', SQLERRM,
                'error_code', SQLSTATE,
                'deletion_summary', json_build_object(
                    'schedules_deleted', 0,
                    'attendance_records_deleted', 0,
                    'exchange_requests_deleted', 0,
                    'backup_created', false,
                    'hours_back', p_hours_back,
                    'executed_by', p_executed_by,
                    'deletion_timestamp', NOW()
                )
            );
    END;
END;
$$;

-- =====================================================
-- RPC FUNCTION 4: Restore Schedules from Backup
-- =====================================================
CREATE OR REPLACE FUNCTION restore_schedules_from_backup(
    p_hours_back INTEGER DEFAULT 24,
    p_executed_by TEXT DEFAULT 'system'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    restored_count INTEGER;
BEGIN
    -- Start transaction
    BEGIN
        -- Restore schedules from backup
        INSERT INTO employee_schedules
        SELECT 
            id, title, description, start_date_time, end_date_time,
            created_by_admin_id, assigned_user_id, actual_user_id,
            department, location, latitude, longitude, status,
            requirements, created_at, updated_at, notes, is_active,
            tags, custom_fields, assignment_history
        FROM employee_schedules_deletion_backup
        WHERE deletion_timestamp >= NOW() - (p_hours_back || ' hours')::INTERVAL;
        
        GET DIAGNOSTICS restored_count = ROW_COUNT;
        
        -- Log the restoration
        INSERT INTO schedule_deletion_log (
            schedules_deleted,
            attendance_records_deleted,
            exchange_requests_deleted,
            deletion_reason,
            executed_by,
            success
        ) VALUES (
            0, 0, 0,
            'RPC_restore_from_backup',
            p_executed_by,
            true
        );
        
        -- Build success result
        result := json_build_object(
            'success', true,
            'restoration_summary', json_build_object(
                'schedules_restored', restored_count,
                'hours_back', p_hours_back,
                'executed_by', p_executed_by,
                'restoration_timestamp', NOW()
            )
        );
        
        RETURN result;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error
            INSERT INTO schedule_deletion_log (
                schedules_deleted,
                attendance_records_deleted,
                exchange_requests_deleted,
                deletion_reason,
                executed_by,
                success,
                error_message
            ) VALUES (
                0, 0, 0,
                'RPC_restore_from_backup',
                p_executed_by,
                false,
                SQLERRM
            );
            
            -- Return error result
            RETURN json_build_object(
                'success', false,
                'error', SQLERRM,
                'error_code', SQLSTATE
            );
    END;
END;
$$;

-- =====================================================
-- RPC FUNCTION 5: Get Deletion Log
-- =====================================================
CREATE OR REPLACE FUNCTION get_deletion_log(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    logs JSON;
    total_count INTEGER;
BEGIN
    -- Get total count
    SELECT COUNT(*) INTO total_count FROM schedule_deletion_log;
    
    -- Get logs
    SELECT json_agg(
        json_build_object(
            'id', id,
            'deletion_timestamp', deletion_timestamp,
            'schedules_deleted', schedules_deleted,
            'attendance_records_deleted', attendance_records_deleted,
            'exchange_requests_deleted', exchange_requests_deleted,
            'deletion_reason', deletion_reason,
            'executed_by', executed_by,
            'success', success,
            'error_message', error_message
        )
    ) INTO logs
    FROM schedule_deletion_log
    ORDER BY deletion_timestamp DESC
    LIMIT p_limit OFFSET p_offset;
    
    -- Build result
    result := json_build_object(
        'success', true,
        'logs', COALESCE(logs, '[]'::json),
        'pagination', json_build_object(
            'total_count', total_count,
            'limit', p_limit,
            'offset', p_offset,
            'has_more', (p_offset + p_limit) < total_count
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- =====================================================
-- CREATE REQUIRED TABLES
-- =====================================================

-- Create deletion log table if it doesn't exist
CREATE TABLE IF NOT EXISTS schedule_deletion_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deletion_timestamp TIMESTAMPTZ DEFAULT NOW(),
    schedules_deleted INTEGER DEFAULT 0,
    attendance_records_deleted INTEGER DEFAULT 0,
    exchange_requests_deleted INTEGER DEFAULT 0,
    deletion_reason TEXT,
    executed_by TEXT,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_schedule_deletion_log_timestamp ON schedule_deletion_log(deletion_timestamp);
CREATE INDEX IF NOT EXISTS idx_schedule_deletion_log_executed_by ON schedule_deletion_log(executed_by);
CREATE INDEX IF NOT EXISTS idx_schedule_deletion_log_success ON schedule_deletion_log(success);

-- Create backup table if it doesn't exist
CREATE TABLE IF NOT EXISTS employee_schedules_deletion_backup (
    id UUID,
    title TEXT,
    description TEXT,
    start_date_time TIMESTAMPTZ,
    end_date_time TIMESTAMPTZ,
    created_by_admin_id UUID,
    assigned_user_id UUID,
    actual_user_id UUID,
    department TEXT,
    location TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    status TEXT,
    requirements JSONB,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    notes TEXT,
    is_active BOOLEAN,
    tags TEXT[],
    custom_fields JSONB,
    assignment_history JSONB,
    deletion_timestamp TIMESTAMPTZ DEFAULT NOW(),
    deletion_reason TEXT,
    executed_by TEXT
);

-- Create indexes for backup table
CREATE INDEX IF NOT EXISTS idx_backup_deletion_timestamp ON employee_schedules_deletion_backup(deletion_timestamp);
CREATE INDEX IF NOT EXISTS idx_backup_executed_by ON employee_schedules_deletion_backup(executed_by);
CREATE INDEX IF NOT EXISTS idx_backup_deletion_reason ON employee_schedules_deletion_backup(deletion_reason);
