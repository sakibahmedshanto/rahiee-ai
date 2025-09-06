// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AttendanceManagementService extends GetxService {
  static AttendanceManagementService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Clock in with comprehensive data
  Future<Map<String, dynamic>> clockIn({
    required String scheduleId,
    required double latitude,
    required double longitude,
    String? address,
    String? photoUrl,
    Map<String, dynamic>? deviceInfo,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Call the improved clock_in RPC function
      final response = await _supabase.rpc('clock_in', params: {
        'p_employee_id': currentUserId,
        'p_schedule_id': scheduleId,
        'p_check_in_lat': latitude,
        'p_check_in_lng': longitude,
        'p_check_in_address': address,
        'p_device_info': deviceInfo,
        'p_employee_notes': notes,
      });

      if (response != null && response['success'] == true) {
        // Refresh pending approvals if admin
        await loadPendingApprovals();
        
        return {
          'success': true,
          'message': response['message'] ?? 'Clocked in successfully',
          'attendance_id': response['attendance_id'],
          'schedule_title': response['schedule_title'],
          'check_in_time': response['check_in_time'],
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

  // Clock out with comprehensive data
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

      final response = await _supabase.rpc('clock_out', params: {
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
          'message': 'Clocked out successfully',
          'total_hours': response['total_hours'],
          'overtime_hours': response['overtime_hours'],
          'calculated_amount': response['calculated_amount'],
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

  // Get today's attendance status for current user
  Future<Map<String, dynamic>?> getTodayAttendanceStatus() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _supabase.rpc('get_employee_attendance_today', params: {
        'p_employee_id': currentUserId,
      });

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting today attendance status: $e');
      return null;
    }
  }

  // Load pending attendance approvals (for admins)
  Future<void> loadPendingApprovals() async {
    try {
      final response = await _supabase.rpc('get_pending_attendance_for_review');
      
      pendingApprovals.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading pending approvals: $e');
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

      final response = await _supabase.rpc('bulk_update_attendance_status', params: {
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
      
      final response = await _supabase.rpc('get_attendance_by_date_range', params: {
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

  // Get attendance metrics and analytics
  Future<Map<String, dynamic>?> getAttendanceMetrics({
    DateTime? startDate,
    DateTime? endDate,
    String? departmentFilter,
  }) async {
    try {
      final response = await _supabase.rpc('calculate_attendance_metrics', params: {
        'p_start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 30))).toIso8601String().split('T')[0],
        'p_end_date': (endDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'p_department_filter': departmentFilter,
      });

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting attendance metrics: $e');
      return null;
    }
  }

  // Create manual attendance entry (for corrections)
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

  // Get current user's active attendance (if any)
  Future<Map<String, dynamic>?> getCurrentActiveAttendance() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('attendance')
          .select('*')
          .eq('employee_id', currentUserId)
          .eq('date', DateTime.now().toIso8601String().split('T')[0])
          .isFilter('check_out_time', null)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error getting active attendance: $e');
      return null;
    }
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

  // Get schedule swap summary
  Future<List<Map<String, dynamic>>> getScheduleSwapSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc('get_schedule_swap_summary', params: {
        'p_start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 30))).toIso8601String().split('T')[0],
        'p_end_date': (endDate ?? DateTime.now()).toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting schedule swap summary: $e');
      return [];
    }
  }

  // Get daily schedule accountability
  Future<List<Map<String, dynamic>>> getDailyScheduleAccountability({
    DateTime? date,
  }) async {
    try {
      final response = await _supabase.rpc('get_daily_schedule_accountability', params: {
        'p_date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(response ?? []);
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
