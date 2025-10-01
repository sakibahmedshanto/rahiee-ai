// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AttendanceManagementService extends GetxService {
  static AttendanceManagementService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;
  
  SupabaseClient get _supabase => _supabaseService.client!;

  SupabaseClient _requireClient() {
    final client = _supabaseService.client;
    if (client == null) {
      throw Exception('Supabase client not initialized');
    }
    return client;
  }

  // Observable lists for attendance management
  final RxList<Map<String, dynamic>> pendingApprovals = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> attendanceHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employeeSummaries = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingApprovals();
  }

  // Clock in with comprehensive data (creates pending attendance)
  Future<Map<String, dynamic>> clockIn({
    String? scheduleId,
    required double latitude,
    required double longitude,
    String? address,
    String? photoUrl,
    Map<String, dynamic>? deviceInfo,
    String? notes,
    String? workType = 'regular',
    String? shiftType,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Call the new create_pending_attendance RPC function
      if (!_supabaseService.isInitialized) {
        throw Exception('Supabase service not initialized');
      }
      
      final response = await _requireClient().rpc('create_pending_attendance', params: {
        'p_employee_id': currentUserId,
        'p_schedule_id': scheduleId,
        'p_check_in_lat': latitude,
        'p_check_in_lng': longitude,
        'p_check_in_address': address,
        'p_device_info': deviceInfo,
        'p_employee_notes': notes,
        'p_work_type': workType,
        'p_shift_type': shiftType,
      });

      if (response != null && response['success'] == true) {
        // Refresh pending approvals if admin
        await loadPendingApprovals();
        
        return {
          'success': true,
          'message': response['message'] ?? 'Clocked in successfully. Waiting for admin approval.',
          'attendance_id': response['attendance_id'],
          'check_in_time': response['check_in_time'],
          'status': response['status'],
          'is_late': response['is_late'] ?? false,
          'expected_hours': response['expected_hours'] ?? 8.0,
          'schedule_title': response['schedule_title'],
          'schedule_location': response['schedule_location'],
          'scheduled_start': response['scheduled_start'],
          'scheduled_end': response['scheduled_end'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Clock in failed',
        };
      }
    } catch (e) {
      print('Error clocking in: $e');
      return {
        'success': false,
        'message': 'Failed to clock in: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Clock out with comprehensive data (will remain pending for admin approval)
  Future<Map<String, dynamic>> clockOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? address,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _requireClient().rpc('complete_attendance_checkout', params: {
        'p_attendance_id': attendanceId,
        'p_employee_id': currentUserId,
        'p_check_out_lat': latitude,
        'p_check_out_lng': longitude,
        'p_check_out_address': address,
        'p_employee_notes': notes,
      });

      if (response != null && response['success'] == true) {
        // Refresh pending approvals if admin
        await loadPendingApprovals();
        
        return {
          'success': true,
          'message': response['message'] ?? 'Clocked out successfully. Waiting for admin approval.',
          'attendance_id': attendanceId,
          'check_in_time': response['check_in_time'],
          'check_out_time': response['check_out_time'],
          'total_hours': response['total_work_hours'],
          'overtime_hours': response['overtime_hours'],
          'is_early_departure': response['is_early_departure'] ?? false,
          'status': response['status'],
          'schedule_title': response['schedule_title'],
          'schedule_location': response['schedule_location'],
          'scheduled_end': response['scheduled_end'],
        };
      } else {
        throw Exception(response['message'] ?? 'Clock out failed');
      }
    } catch (e) {
      print('Error clocking out: $e');
      return {
        'success': false,
        'message': 'Failed to clock out: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Get attendance status for a specific date and schedule
  Future<Map<String, dynamic>?> getAttendanceForSchedule({
    required String scheduleId,
    DateTime? date,
    String? employeeId,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return null;
      
      final targetEmployeeId = employeeId ?? currentUserId;
      final targetDate = date ?? DateTime.now();

      final response = await _requireClient().rpc('get_schedule_attendance_status', params: {
        'p_employee_id': targetEmployeeId,
        'p_schedule_id': scheduleId,
        'p_date': targetDate.toIso8601String().split('T')[0],
      });

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting attendance for schedule: $e');
      return null;
    }
  }

  // Get all schedules with their attendance status for a date
  Future<Map<String, dynamic>> getSchedulesWithAttendanceStatus({
    DateTime? date,
    String? employeeId,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        return {
          'error': true,
          'message': 'User not authenticated',
          'schedules': [],
          'total_schedules': 0
        };
      }
      
      final targetEmployeeId = employeeId ?? currentUserId;
      final targetDate = date ?? DateTime.now();

      final response = await _requireClient().rpc('get_schedules_with_attendance_status', params: {
        'p_employee_id': targetEmployeeId,
        'p_date': targetDate.toIso8601String().split('T')[0],
      });

      return response != null ? Map<String, dynamic>.from(response) : {
        'error': true,
        'message': 'Failed to fetch schedules',
        'schedules': [],
        'total_schedules': 0
      };
    } catch (e) {
      print('Error getting schedules with attendance status: $e');
      return {
        'error': true,
        'message': 'Error: $e',
        'schedules': [],
        'total_schedules': 0
      };
    }
  }

  // Check if employee can check in for a specific schedule
  Future<Map<String, dynamic>> canCheckInForSchedule({
    required String scheduleId,
    DateTime? date,
    String? employeeId,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        return {
          'error': true,
          'message': 'User not authenticated',
          'can_check_in': false
        };
      }
      
      final targetEmployeeId = employeeId ?? currentUserId;
      final targetDate = date ?? DateTime.now();

      final response = await _requireClient().rpc('can_check_in_for_schedule', params: {
        'p_employee_id': targetEmployeeId,
        'p_schedule_id': scheduleId,
        'p_date': targetDate.toIso8601String().split('T')[0],
      });

      return response != null ? Map<String, dynamic>.from(response) : {
        'error': true,
        'message': 'Failed to check availability',
        'can_check_in': false
      };
    } catch (e) {
      print('Error checking if can check in: $e');
      return {
        'error': true,
        'message': 'Error: $e',
        'can_check_in': false
      };
    }
  }

  // Get attendance status for a specific date (legacy method for backward compatibility)
  Future<Map<String, dynamic>?> getAttendanceForDate({
    DateTime? date,
    String? employeeId,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return null;
      
      final targetEmployeeId = employeeId ?? currentUserId;
      final targetDate = date ?? DateTime.now();

      final response = await _requireClient().rpc('get_schedule_attendance_status', params: {
        'p_employee_id': targetEmployeeId,
        'p_schedule_id': null, // Get most recent attendance for any schedule
        'p_date': targetDate.toIso8601String().split('T')[0],
      });

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting attendance for date: $e');
      return null;
    }
  }

  // Get attendance for a date range (using optimized RPC)
  Future<List<Map<String, dynamic>>> getAttendanceForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
    String? status,
    String? department,
    bool includeScheduleInfo = true,
    int limit = 100,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return [];
      
      final targetEmployeeId = employeeId ?? currentUserId;

      final response = await _requireClient().rpc('get_attendance_for_date_range_detailed', params: {
        'p_employee_id': targetEmployeeId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
        'p_status': status,
        'p_department': department,
        'p_include_schedule_info': includeScheduleInfo,
        'p_limit': limit,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting attendance for date range: $e');
      return [];
    }
  }

  // Get today's attendance status for current user (convenience method)
  Future<Map<String, dynamic>?> getTodayAttendanceStatus() async {
    return await getAttendanceForDate(date: DateTime.now());
  }

  // Load pending attendance approvals with filters (for admins)
  Future<List<Map<String, dynamic>>> loadPendingApprovalsWithFilters({
    String? department,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 100,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      
      final response = await _requireClient().rpc('get_pending_attendance_for_admin_review', params: {
        'p_admin_id': currentUserId,
        'p_department': department,
        'p_date_from': dateFrom?.toIso8601String().split('T')[0],
        'p_date_to': dateTo?.toIso8601String().split('T')[0],
        'p_limit': limit,
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading pending approvals with filters: $e');
      return [];
    }
  }

  // Load pending attendance approvals (for admins)
  Future<void> loadPendingApprovals() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      
      final response = await _requireClient().rpc('get_pending_attendance_for_admin_review', params: {
        'p_admin_id': currentUserId,
        'p_limit': 100,
      });
      
      pendingApprovals.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading pending approvals: $e');
      // If user doesn't have admin privileges, just clear the list
      pendingApprovals.value = [];
    }
  }

  // Admin method to update attendance status (approve/reject)
  Future<Map<String, dynamic>> adminUpdateAttendanceStatus({
    required String attendanceId,
    required String newStatus, // 'granted', 'not_granted', 'approved', 'rejected', 'cancelled'
    String? adminNotes,
    String? reviewReason,
    double? calculatedAmount,
    double? adjustedHours,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _requireClient().rpc('admin_update_attendance_status', params: {
        'p_attendance_id': attendanceId,
        'p_admin_id': currentUserId,
        'p_new_status': newStatus,
        'p_admin_notes': adminNotes,
        'p_review_reason': reviewReason,
        'p_calculated_amount': calculatedAmount,
        'p_adjusted_hours': adjustedHours,
      });

      if (response != null && response['success'] == true) {
        // Refresh pending approvals
        await loadPendingApprovals();
        
        return {
          'success': true,
          'message': response['message'] ?? 'Attendance status updated successfully',
          'attendance_id': response['attendance_id'],
          'employee_name': response['employee_name'],
          'previous_status': response['previous_status'],
          'new_status': response['new_status'],
          'reviewed_by': response['reviewed_by'],
          'reviewed_at': response['reviewed_at'],
          'total_work_hours': response['total_work_hours'],
          'net_work_hours': response['net_work_hours'],
          'overtime_hours': response['overtime_hours'],
          'calculated_amount': response['calculated_amount'],
          'overtime_amount': response['overtime_amount'],
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to update attendance status');
      }
    } catch (e) {
      print('Error updating attendance status: $e');
      return {
        'success': false,
        'message': 'Failed to update attendance status: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Bulk approve/reject attendance records
  Future<Map<String, dynamic>> bulkUpdateAttendanceStatus({
    required List<String> attendanceIds,
    required String status, // 'granted', 'not_granted'
    String? adminNotes,
    String? reviewReason,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _requireClient().rpc('bulk_update_attendance_status', params: {
        'p_attendance_ids': attendanceIds,
        'p_status': status,
        'p_reviewed_by': currentUserId,
        'p_admin_notes': adminNotes,
        'p_review_reason': reviewReason,
      });

      if (response != null && response['success'] == true) {
        // Refresh pending approvals
        await loadPendingApprovals();
        
        return {
          'success': true,
          'message': '${response['updated_count']} records updated successfully',
          'updated_count': response['updated_count'],
        };
      } else {
        throw Exception(response['message'] ?? 'Bulk update failed');
      }
    } catch (e) {
      print('Error in bulk update: $e');
      return {
        'success': false,
        'message': 'Failed to update records: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Get attendance history for date range
  Future<void> loadAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? status,
  }) async {
    try {
      isLoading.value = true;
      
      final response = await _requireClient().rpc('get_attendance_by_date_range', params: {
        'p_start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 30))).toIso8601String().split('T')[0],
        'p_end_date': (endDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'p_employee_id': employeeId,
        'p_status_filter': status,
      });

      attendanceHistory.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading attendance history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get employee attendance summaries
  Future<void> loadEmployeeSummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      isLoading.value = true;
      
      final response = await _supabase
          .from('employee_performance_dashboard')
          .select();

      employeeSummaries.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading employee summaries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Gets summary data for swap requests (placeholder - function removed from DB)
  Future<Map<String, dynamic>?> getSwapSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This function was calling get_schedule_swap_summary which was removed
      // Return empty result for now
      return {
        'success': false,
        'message': 'Swap summary function is not available',
        'data': [],
      };
    } catch (e) {
      print('Error getting swap summary: $e');
      return null;
    }
  }

  /// Create manual attendance entry (for corrections)
  Future<Map<String, dynamic>> createManualAttendance({
    required String employeeId,
    required DateTime date,
    required DateTime checkInTime,
    required DateTime checkOutTime,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate work hours
      final totalHours = checkOutTime.difference(checkInTime).inMinutes / 60.0;
      
      final attendanceData = {
        'employee_id': employeeId,
        'date': date.toIso8601String().split('T')[0],
        'check_in_time': checkInTime.toIso8601String(),
        'check_out_time': checkOutTime.toIso8601String(),
        'total_work_hours': totalHours,
        'net_work_hours': totalHours,
        'status': 'granted', // Manual entries are pre-approved
        'reviewed_by': currentUserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'admin_notes': adminNotes ?? 'Manual entry: $reason',
        'review_reason': 'manual_entry',
        'work_type': 'regular',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('attendance')
          .insert(attendanceData)
          .select()
          .single();

      // Refresh data
      await loadPendingApprovals();
      await loadAttendanceHistory();
      
      return {
        'success': true,
        'message': 'Manual attendance entry created successfully',
        'attendance_id': response['id'],
      };
    } catch (e) {
      print('Error creating manual attendance: $e');
      return {
        'success': false,
        'message': 'Failed to create manual entry: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Update attendance record (for corrections)
  Future<Map<String, dynamic>> updateAttendanceRecord({
    required String attendanceId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    String? adminNotes,
    String? reviewReason,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'reviewed_by': currentUserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (checkInTime != null) updateData['check_in_time'] = checkInTime.toIso8601String();
      if (checkOutTime != null) updateData['check_out_time'] = checkOutTime.toIso8601String();
      if (status != null) updateData['status'] = status;
      if (adminNotes != null) updateData['admin_notes'] = adminNotes;
      if (reviewReason != null) updateData['review_reason'] = reviewReason;

      // Recalculate hours if times are updated
      if (checkInTime != null && checkOutTime != null) {
        final totalHours = checkOutTime.difference(checkInTime).inMinutes / 60.0;
        updateData['total_work_hours'] = totalHours;
        updateData['net_work_hours'] = totalHours;
      }

      await _supabase
          .from('attendance')
          .update(updateData)
          .eq('id', attendanceId)
          .select()
          .single();

      // Refresh data
      await loadPendingApprovals();
      await loadAttendanceHistory();
      
      return {
        'success': true,
        'message': 'Attendance record updated successfully',
      };
    } catch (e) {
      print('Error updating attendance record: $e');
      return {
        'success': false,
        'message': 'Failed to update record: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Delete attendance record (admin only)
  Future<Map<String, dynamic>> deleteAttendanceRecord(String attendanceId) async {
    try {
      isLoading.value = true;
      
      await _supabase
          .from('attendance')
          .delete()
          .eq('id', attendanceId);

      // Refresh data
      await loadPendingApprovals();
      await loadAttendanceHistory();
      
      return {
        'success': true,
        'message': 'Attendance record deleted successfully',
      };
    } catch (e) {
      print('Error deleting attendance record: $e');
      return {
        'success': false,
        'message': 'Failed to delete record: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Get current user's active attendance for a specific date (if any)
  Future<Map<String, dynamic>?> getActiveAttendanceForDate({
    DateTime? date,
    String? employeeId,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return null;

      final targetEmployeeId = employeeId ?? currentUserId;
      final targetDate = date ?? DateTime.now();

      final response = await _supabase
          .from('attendance')
          .select('''
            *,
            schedule:employee_schedules!schedule_id(
              id, title, start_date_time, end_date_time, location, department
            ),
            employee:my_users!user_id(
              full_name, employee_id, department, position
            )
          ''')
          .eq('user_id', targetEmployeeId)
          .eq('date', targetDate.toIso8601String().split('T')[0])
          .isFilter('check_out_time', null)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting active attendance for date: $e');
      return null;
    }
  }

  // Get current user's active attendance (convenience method for today)
  Future<Map<String, dynamic>?> getCurrentActiveAttendance() async {
    return await getActiveAttendanceForDate(date: DateTime.now());
  }

  // Get all attendance records for multiple employees in a date range (admin function)
  Future<List<Map<String, dynamic>>> getMultiEmployeeAttendance({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? employeeIds,
    String? department,
    String? status,
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('attendance')
          .select('''
            *,
            schedule:employee_schedules!schedule_id(
              id, title, start_date_time, end_date_time, location, department
            ),
            employee:my_users!user_id(
              full_name, employee_id, department, position
            ),
            reviewed_by_user:my_users!reviewed_by(
              full_name
            )
          ''')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (employeeIds != null && employeeIds.isNotEmpty) {
        query = query.inFilter('user_id', employeeIds);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (department != null) {
        query = query.eq('employee.department', department);
      }

      var finalQuery = query.order('date', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting multi-employee attendance: $e');
      return [];
    }
  }

  // Get attendance summary for a specific period (using optimized RPC)
  Future<Map<String, dynamic>> getAttendanceSummaryForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      
      final targetEmployeeId = employeeId ?? currentUserId;

      final response = await _supabase.rpc('get_attendance_summary_for_period', params: {
        'p_employee_id': targetEmployeeId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });

      return response != null ? Map<String, dynamic>.from(response) : {
        'success': false, 
        'message': 'No data returned'
      };
    } catch (e) {
      print('Error getting attendance summary: $e');
      return {'success': false, 'message': 'Failed to get attendance summary: $e'};
    }
  }

  // Convenience methods for common date range queries
  
  // Get this week's attendance
  Future<List<Map<String, dynamic>>> getThisWeekAttendance({String? employeeId}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return await getAttendanceForDateRange(
      startDate: startOfWeek,
      endDate: endOfWeek,
      employeeId: employeeId,
    );
  }

  // Get this month's attendance
  Future<List<Map<String, dynamic>>> getThisMonthAttendance({String? employeeId}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return await getAttendanceForDateRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
      employeeId: employeeId,
    );
  }

  // Get last 30 days attendance
  Future<List<Map<String, dynamic>>> getLast30DaysAttendance({String? employeeId}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    
    return await getAttendanceForDateRange(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
    );
  }

  // Get pending attendance for a specific date range
  Future<List<Map<String, dynamic>>> getPendingAttendanceForRange({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) async {
    return await getAttendanceForDateRange(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      status: 'pending',
    );
  }

  // Get approved attendance for a specific date range
  Future<List<Map<String, dynamic>>> getApprovedAttendanceForRange({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) async {
    return await getAttendanceForDateRange(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      status: 'granted',
    );
  }

  // Get attendance statistics for current user
  Future<Map<String, dynamic>?> getUserAttendanceStats() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('monthly_employee_summary')
          .select()
          .eq('employee_id', currentUserId)
          .eq('year', DateTime.now().year)
          .eq('month', DateTime.now().month)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting user attendance stats: $e');
      return null;
    }
  }

  // Export attendance data
  Future<List<Map<String, dynamic>>> exportAttendanceData({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? department,
    String? status,
  }) async {
    try {
      final finalQuery = _supabase
          .from('attendance')
          .select('''
            *, 
            employee:my_users!employee_id(full_name, employee_id, department, position),
            reviewed_by_user:my_users!reviewed_by(full_name)
          ''');

      if (startDate != null) {
        finalQuery.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        finalQuery.lte('date', endDate.toIso8601String().split('T')[0]);
      }
      if (employeeId != null) {
        finalQuery.eq('employee_id', employeeId);
      }
      if (status != null) {
        finalQuery.eq('status', status);
      }

      final response = await finalQuery.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error exporting attendance data: $e');
      return [];
    }
  }

  // Convenience getters
  int get pendingApprovalsCount => pendingApprovals.length;
  
  List<Map<String, dynamic>> get recentAttendance => 
      attendanceHistory.take(10).toList();
  
  List<Map<String, dynamic>> get criticalApprovals => 
      pendingApprovals.where((attendance) {
        final date = DateTime.tryParse(attendance['date'] ?? '');
        if (date == null) return false;
        return DateTime.now().difference(date).inDays > 2;
      }).toList();

  // Admin Schedule Tracking Methods
  
  // Get comprehensive schedule and attendance report
  Future<List<Map<String, dynamic>>> getAdminScheduleReport({
    DateTime? startDate,
    DateTime? endDate,
    String? department,
    String? employeeId,
  }) async {
    try {
      final response = await _supabase.rpc('get_admin_schedule_report', params: {
        'p_start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 7))).toIso8601String().split('T')[0],
        'p_end_date': (endDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'p_department': department,
        'p_employee_id': employeeId,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting admin schedule report: $e');
      return [];
    }
  }

  /// Get schedule swap summary (placeholder - function removed from DB)
  Future<List<Map<String, dynamic>>> getScheduleSwapSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This function was calling get_schedule_swap_summary which was removed
      // Return empty result for now since swap functionality doesn't exist
      print('Schedule swap summary: Function removed from database');
      return [];
    } catch (e) {
      print('Error getting schedule swap summary: $e');
      return [];
    }
  }

  // Get daily schedule accountability
  /// Get daily schedule accountability (placeholder - function removed from DB)
  Future<List<Map<String, dynamic>>> getDailyScheduleAccountability({
    DateTime? date,
  }) async {
    try {
      // This function was calling get_daily_schedule_accountability which was removed
      // Return empty result for now since the daily_schedule_assignments table doesn't exist
      print('Daily schedule accountability: Function removed from database');
      return [];
    } catch (e) {
      print('Error getting daily schedule accountability: $e');
      return [];
    }
  }

  // Get employee's available schedules for check-in
  Future<List<Map<String, dynamic>>> getAvailableSchedulesForEmployee({
    DateTime? date,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return [];

      final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];
      
      // Get schedules assigned to this employee
      final assignedSchedules = await _supabase
          .from('employee_schedules')
          .select('''
            id, title, start_date_time, end_date_time, location, description,
            department, status
          ''')
          .eq('assigned_user_id', currentUserId)
          .gte('start_date_time', '${targetDate}T00:00:00')
          .lt('start_date_time', '${targetDate}T23:59:59')
          .order('start_date_time');

      // Get schedules available through approved swaps
      final swappedSchedules = await _supabase
          .from('schedule_swap_requests')
          .select('''
            original_schedule_id,
            target_schedule_id,
            employee_schedules!original_schedule_id(
              id, title, start_date_time, end_date_time, location, description,
              department, status
            )
          ''')
          .eq('requesting_employee_id', currentUserId)
          .eq('status', 'approved')
          .gte('employee_schedules.start_date_time', '${targetDate}T00:00:00')
          .lt('employee_schedules.start_date_time', '${targetDate}T23:59:59');

      final allSchedules = <Map<String, dynamic>>[];
      
      // Add assigned schedules
      for (var schedule in assignedSchedules) {
        allSchedules.add({
          ...schedule,
          'schedule_type': 'assigned',
          'can_check_in': true,
        });
      }

      // Add swapped schedules
      for (var swap in swappedSchedules) {
        final schedule = swap['employee_schedules'];
        if (schedule != null) {
          allSchedules.add({
            ...schedule,
            'schedule_type': 'swapped',
            'swap_request_id': swap['id'],
            'can_check_in': true,
          });
        }
      }

      return allSchedules;
    } catch (e) {
      print('Error getting available schedules: $e');
      return [];
    }
  }

  // Get attendance details with schedule information
  Future<Map<String, dynamic>?> getAttendanceWithScheduleDetails(String attendanceId) async {
    try {
      final response = await _supabase
          .from('admin_attendance_tracking')
          .select('*')
          .eq('attendance_id', attendanceId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting attendance with schedule details: $e');
      return null;
    }
  }
}
