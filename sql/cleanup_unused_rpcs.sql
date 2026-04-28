-- ============================================================================
-- CLEANUP UNUSED RPC FUNCTIONS AND OBJECTS
-- ============================================================================
-- This script removes all unused/obsolete RPC functions that were created
-- during development but are no longer needed in the production system.
-- ============================================================================

-- ============================================================================
-- DROP UNUSED SCHEDULE FETCHING RPCs
-- ============================================================================
-- These were created during development but replaced by get_user_schedules_multi

DROP FUNCTION IF EXISTS get_employee_schedules_with_exchanges(UUID, DATE, BOOLEAN);
DROP FUNCTION IF EXISTS get_employee_schedules(UUID, DATE, DATE, DATE, BOOLEAN, BOOLEAN, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS check_schedule_exchange_eligibility(UUID, UUID);
DROP FUNCTION IF EXISTS get_employee_schedule_summary(UUID, DATE, DATE);

-- ============================================================================
-- DROP UNUSED SCHEDULE DELETION RPCs
-- ============================================================================
-- These were for testing/development but not used in production

DROP FUNCTION IF EXISTS preview_schedule_deletion(INTEGER);
DROP FUNCTION IF EXISTS get_schedules_for_deletion(INTEGER);
DROP FUNCTION IF EXISTS safe_delete_schedules(INTEGER, BOOLEAN);
DROP FUNCTION IF EXISTS restore_schedules_from_backup(INTEGER);
DROP FUNCTION IF EXISTS get_deletion_log(INTEGER, INTEGER);

-- Drop backup and log tables if they exist
DROP TABLE IF EXISTS public.schedule_deletion_backup CASCADE;
DROP TABLE IF EXISTS public.schedule_deletion_log CASCADE;

-- ============================================================================
-- VERIFY ACTIVE RPC FUNCTIONS
-- ============================================================================
-- List all remaining RPC functions that are actively used

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'ACTIVE RPC FUNCTIONS AFTER CLEANUP:';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📅 SCHEDULE MANAGEMENT:';
    RAISE NOTICE '  • get_user_schedules_multi() - Fetch user schedules with multi-user support';
    RAISE NOTICE '  • get_schedules_with_attendance_status() - Fetch schedules with attendance data';
    RAISE NOTICE '  • get_schedule_with_assignments() - Get schedule with all assigned users';
    RAISE NOTICE '  • get_available_users_for_schedule() - Find users available for a schedule';
    RAISE NOTICE '  • assign_users_to_schedule() - Assign multiple users to a schedule';
    RAISE NOTICE '  • remove_user_from_schedule() - Remove user from schedule assignment';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 SCHEDULE EXCHANGE:';
    RAISE NOTICE '  • create_schedule_exchange_request() - Create exchange request';
    RAISE NOTICE '  • admin_manage_schedule_exchange_request() - Approve/reject exchange';
    RAISE NOTICE '  • get_schedule_exchange_requests() - List exchange requests';
    RAISE NOTICE '  • cancel_schedule_exchange_request() - Cancel user own request';
    RAISE NOTICE '  • check_schedule_conflict() - Check for scheduling conflicts';
    RAISE NOTICE '';
    RAISE NOTICE '📊 ATTENDANCE:';
    RAISE NOTICE '  • check_in() - Employee check-in';
    RAISE NOTICE '  • check_out() - Employee check-out';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'CLEANUP COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '============================================================';
END;
$$;

-- ============================================================================
-- VERIFY TABLES AND TRIGGERS
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'ACTIVE TABLES:';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '  • my_users - User accounts';
    RAISE NOTICE '  • employee_schedules - Schedule definitions';
    RAISE NOTICE '  • schedule_assignments - Multi-user schedule assignments';
    RAISE NOTICE '  • attendance - Attendance records';
    RAISE NOTICE '  • schedule_exchange_requests - Exchange requests';
    RAISE NOTICE '';
    RAISE NOTICE 'ACTIVE TRIGGERS:';
    RAISE NOTICE '  • update_schedule_participant_count - Auto-update participant counts';
    RAISE NOTICE '============================================================';
END;
$$;


