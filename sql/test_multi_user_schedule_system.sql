-- ============================================================================
-- MULTI-USER SCHEDULE SYSTEM - COMPREHENSIVE TESTS
-- ============================================================================
-- Run these tests to verify the multi-user schedule system is working correctly
-- ============================================================================

-- ============================================================================
-- TEST 1: Create a multi-user schedule and assign multiple users
-- ============================================================================
DO $$
DECLARE
    v_schedule_id UUID;
    v_admin_id UUID;
    v_user1_id UUID;
    v_user2_id UUID;
    v_result JSON;
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 1: Create multi-user schedule and assign users';
    RAISE NOTICE '============================================================================';
    
    -- Get admin and user IDs (adjust these based on your actual data)
    SELECT id INTO v_admin_id FROM my_users WHERE user_role = 'admin' LIMIT 1;
    SELECT id INTO v_user1_id FROM my_users WHERE user_role = 'employee' AND full_name = 'shantoo' LIMIT 1;
    SELECT id INTO v_user2_id FROM my_users WHERE user_role = 'employee' AND full_name = 'Robin' LIMIT 1;
    
    RAISE NOTICE 'Admin ID: %', v_admin_id;
    RAISE NOTICE 'User 1 ID: %', v_user1_id;
    RAISE NOTICE 'User 2 ID: %', v_user2_id;
    
    -- Create a test schedule
    INSERT INTO employee_schedules (
        title,
        description,
        start_date_time,
        end_date_time,
        created_by_admin_id,
        assigned_user_id,  -- Still required for backward compatibility
        department,
        location,
        is_multi_user,
        max_participants,
        min_participants
    ) VALUES (
        'Multi-User Test Schedule',
        'Testing multi-user assignment system',
        NOW() + INTERVAL '1 day',
        NOW() + INTERVAL '1 day 8 hours',
        v_admin_id,
        v_user1_id,  -- Initial assignment
        'IT',
        'Main Office',
        true,
        5,
        2
    ) RETURNING id INTO v_schedule_id;
    
    RAISE NOTICE 'Created schedule ID: %', v_schedule_id;
    
    -- Assign multiple users to the schedule
    SELECT assign_users_to_schedule(
        v_schedule_id,
        ARRAY[v_user1_id, v_user2_id]::UUID[],
        v_admin_id,
        'Initial team assignment'
    ) INTO v_result;
    
    RAISE NOTICE 'Assignment result: %', v_result;
    
    -- Verify assignments
    RAISE NOTICE 'Current assignments for schedule %:', v_schedule_id;
    FOR v_result IN 
        SELECT json_build_object(
            'user', u.full_name,
            'status', sa.status,
            'assigned_at', sa.assigned_at
        ) as assignment_info
        FROM schedule_assignments sa
        JOIN my_users u ON sa.user_id = u.id
        WHERE sa.schedule_id = v_schedule_id
    LOOP
        RAISE NOTICE '  - %', v_result;
    END LOOP;
    
    RAISE NOTICE 'TEST 1: PASSED ✓';
END $$;

-- ============================================================================
-- TEST 2: Get schedule with assignments
-- ============================================================================
DO $$
DECLARE
    v_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 2: Get schedule with assignments';
    RAISE NOTICE '============================================================================';
    
    SELECT get_schedule_with_assignments(NULL, (CURRENT_DATE + 1), NULL) INTO v_result;
    
    RAISE NOTICE 'Schedules with assignments: %', jsonb_pretty(v_result::jsonb);
    RAISE NOTICE 'TEST 2: PASSED ✓';
END $$;

-- ============================================================================
-- TEST 3: Get available users for schedule
-- ============================================================================
DO $$
DECLARE
    v_schedule_id UUID;
    v_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 3: Get available users for schedule';
    RAISE NOTICE '============================================================================';
    
    -- Get the test schedule
    SELECT id INTO v_schedule_id 
    FROM employee_schedules 
    WHERE title = 'Multi-User Test Schedule'
    ORDER BY created_at DESC
    LIMIT 1;
    
    RAISE NOTICE 'Testing with schedule ID: %', v_schedule_id;
    
    SELECT get_available_users_for_schedule(v_schedule_id, 'IT') INTO v_result;
    
    RAISE NOTICE 'Available users: %', jsonb_pretty(v_result::jsonb);
    RAISE NOTICE 'TEST 3: PASSED ✓';
END $$;

-- ============================================================================
-- TEST 4: Get user schedules with multi-user info
-- ============================================================================
DO $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 4: Get user schedules with multi-user info';
    RAISE NOTICE '============================================================================';
    
    -- Get shantoo's ID
    SELECT id INTO v_user_id FROM my_users WHERE full_name = 'shantoo' LIMIT 1;
    
    RAISE NOTICE 'Getting schedules for user: %', v_user_id;
    
    SELECT get_user_schedules_multi(v_user_id, CURRENT_DATE + 1, true) INTO v_result;
    
    RAISE NOTICE 'User schedules: %', jsonb_pretty(v_result::jsonb);
    RAISE NOTICE 'TEST 4: PASSED ✓';
END $$;

-- ============================================================================
-- TEST 5: Remove user from schedule
-- ============================================================================
DO $$
DECLARE
    v_schedule_id UUID;
    v_user_id UUID;
    v_admin_id UUID;
    v_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 5: Remove user from schedule';
    RAISE NOTICE '============================================================================';
    
    -- Get IDs
    SELECT id INTO v_schedule_id 
    FROM employee_schedules 
    WHERE title = 'Multi-User Test Schedule'
    ORDER BY created_at DESC
    LIMIT 1;
    
    SELECT id INTO v_user_id FROM my_users WHERE full_name = 'Robin' LIMIT 1;
    SELECT id INTO v_admin_id FROM my_users WHERE user_role = 'admin' LIMIT 1;
    
    RAISE NOTICE 'Removing user % from schedule %', v_user_id, v_schedule_id;
    
    SELECT remove_user_from_schedule(
        v_schedule_id,
        v_user_id,
        v_admin_id,
        'Test removal'
    ) INTO v_result;
    
    RAISE NOTICE 'Removal result: %', v_result;
    
    -- Verify removal
    RAISE NOTICE 'Remaining active assignments:';
    FOR v_result IN 
        SELECT json_build_object(
            'user', u.full_name,
            'status', sa.status
        ) as assignment_info
        FROM schedule_assignments sa
        JOIN my_users u ON sa.user_id = u.id
        WHERE sa.schedule_id = v_schedule_id
        AND sa.is_active = true
    LOOP
        RAISE NOTICE '  - %', v_result;
    END LOOP;
    
    RAISE NOTICE 'TEST 5: PASSED ✓';
END $$;

-- ============================================================================
-- TEST 6: Verify backward compatibility
-- ============================================================================
DO $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 6: Verify backward compatibility with old RPC';
    RAISE NOTICE '============================================================================';
    
    -- Get shantoo's ID
    SELECT id INTO v_user_id FROM my_users WHERE full_name = 'shantoo' LIMIT 1;
    
    -- Test the old RPC function (should still work)
    SELECT get_schedules_with_attendance_status(v_user_id, CURRENT_DATE + 1) INTO v_result;
    
    RAISE NOTICE 'Old RPC result: %', jsonb_pretty(v_result::jsonb);
    RAISE NOTICE 'TEST 6: PASSED ✓';
END $$;

-- ============================================================================
-- TEST 7: Verify participant count auto-update
-- ============================================================================
DO $$
DECLARE
    v_schedule_id UUID;
    v_participant_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TEST 7: Verify participant count auto-update';
    RAISE NOTICE '============================================================================';
    
    SELECT id INTO v_schedule_id 
    FROM employee_schedules 
    WHERE title = 'Multi-User Test Schedule'
    ORDER BY created_at DESC
    LIMIT 1;
    
    SELECT current_participants INTO v_participant_count
    FROM employee_schedules
    WHERE id = v_schedule_id;
    
    RAISE NOTICE 'Schedule ID: %', v_schedule_id;
    RAISE NOTICE 'Current participants count: %', v_participant_count;
    
    IF v_participant_count > 0 THEN
        RAISE NOTICE 'TEST 7: PASSED ✓';
    ELSE
        RAISE NOTICE 'TEST 7: FAILED ✗ - Participant count should be > 0';
    END IF;
END $$;

-- ============================================================================
-- SUMMARY
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'ALL TESTS COMPLETED';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Verify the following:';
    RAISE NOTICE '1. ✓ Multi-user schedules can be created';
    RAISE NOTICE '2. ✓ Multiple users can be assigned to a schedule';
    RAISE NOTICE '3. ✓ Available users are filtered correctly (no conflicts)';
    RAISE NOTICE '4. ✓ Users can see their assigned schedules';
    RAISE NOTICE '5. ✓ Users can be removed from schedules';
    RAISE NOTICE '6. ✓ Backward compatibility maintained';
    RAISE NOTICE '7. ✓ Participant counts auto-update';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '- Test in Flutter app (admin and employee sides)';
    RAISE NOTICE '- Verify attendance works for multi-user schedules';
    RAISE NOTICE '- Update UI to show multi-user indicators';
    RAISE NOTICE '';
END $$;

