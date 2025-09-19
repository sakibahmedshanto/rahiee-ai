import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin/admin_dashboard_model.dart';
import '../../models/admin/attendance_audit_model.dart';
import '../../models/admin/payment_record_model.dart';
import '../../models/admin/schedule_coverage_model.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../models/schedule_model.dart';
import '../../utils/app_constant.dart';

class AdminController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Reactive state variables
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Dashboard data
  final Rx<AdminDashboardSummaryModel?> dashboardSummary = Rx<AdminDashboardSummaryModel?>(null);
  
  // Employee management
  final RxList<UserModel> allEmployees = <UserModel>[].obs;
  final RxList<UserModel> filteredEmployees = <UserModel>[].obs;
  final RxString employeeSearchQuery = ''.obs;
  final RxString selectedDepartment = 'All'.obs;
  final RxList<String> departments = <String>['All'].obs;
  
  // Attendance management
  final RxList<AttendanceModel> pendingAttendance = <AttendanceModel>[].obs;
  final RxList<AttendanceModel> allAttendance = <AttendanceModel>[].obs;
  final RxList<AttendanceAuditModel> auditLogs = <AttendanceAuditModel>[].obs;
  final RxString selectedAttendanceFilter = 'pending'.obs;
  
  // Store raw attendance data with employee info for UI access
  final RxMap<String, Map<String, dynamic>> attendanceRawData = <String, Map<String, dynamic>>{}.obs;
  
  // Date filtering for attendance
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);
  final RxString dateFilterType = 'today'.obs; // 'today', 'range', 'all'
  
  // Table specific filters
  final RxString tableSelectedDepartment = 'All Departments'.obs;
  final RxString tableSelectedStatus = 'All Status'.obs;
  final RxString tableSelectedDateRange = 'Today'.obs;
  final RxBool isTableLoading = false.obs;
  final RxInt tableCurrentPage = 1.obs;
  final RxInt tableItemsPerPage = 20.obs;
  final RxInt tableTotalRecords = 0.obs;
  final RxList<Map<String, dynamic>> tableAttendanceList = <Map<String, dynamic>>[].obs;
  
  // Schedule management
  final RxList<ScheduleModel> activeSchedules = <ScheduleModel>[].obs;
  final RxList<ScheduleCoverageModel> coverageRequests = <ScheduleCoverageModel>[].obs;
  
  // Payment management
  final RxList<PaymentRecordModel> paymentRecords = <PaymentRecordModel>[].obs;
  
  // Filters and pagination
  final RxString selectedTimeRange = 'Today'.obs;
  final RxString selectedStatus = 'All'.obs;
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 20.obs;
  
  // Analytics
  final RxInt totalActiveEmployees = 0.obs;
  final RxInt totalCheckedInToday = 0.obs;
  final RxInt totalPendingApprovals = 0.obs;
  final RxDouble totalUnpaidAmount = 0.0.obs;
  final RxDouble monthlyPayrollTotal = 0.0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeController();
    _setupRealtimeSubscriptions();
  }

  void _initializeController() async {
    // Set default date filter to today
    dateFilterType.value = 'today';
    await loadInitialData();
  }

  void _setupRealtimeSubscriptions() {
    // Listen to attendance changes
    _supabase
        .channel('admin_attendance_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (payload) {
            print('Attendance change detected: ${payload.eventType}');
            _handleAttendanceChange(payload);
          },
        )
        .subscribe();

    // Listen to user changes
    _supabase
        .channel('admin_user_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'my_users',
          callback: (payload) {
            print('User change detected: ${payload.eventType}');
            _handleUserChange(payload);
          },
        )
        .subscribe();

    // Listen to schedule changes
    _supabase
        .channel('admin_schedule_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'employee_schedules',
          callback: (payload) {
            print('Schedule change detected: ${payload.eventType}');
            _handleScheduleChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load data in parallel for better performance
      await Future.wait([
        loadDashboardSummary(),
        loadAllEmployees(),
        loadPendingAttendance(),
        loadActiveSchedules(),
        // loadRecentAuditLogs(), // Disabled: table doesn't exist yet
      ]);

    } catch (e) {
      errorMessage.value = 'Failed to load admin data: ${e.toString()}';
      print('Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    try {
      isRefreshing.value = true;
      await loadInitialData();
    } finally {
      isRefreshing.value = false;
    }
  }

  // Dashboard Summary
  Future<void> loadDashboardSummary() async {
    try {
      final response = await _supabase.rpc('get_attendance_dashboard_summary', 
        params: {'summary_date': DateTime.now().toIso8601String().split('T')[0]}
      );
      
      if (response != null && response['success'] == true) {
        final data = response['data'];
        final overall = data['overall'];
        final departments = data['departments'] as List? ?? [];
        
        // Transform the response to match the model structure
        final transformedData = {
          'date': DateTime.now().toIso8601String().split('T')[0],
          'total_employees': overall['totalEmployees'] ?? 0,
          'checked_in_today': overall['checkedInToday'] ?? 0,
          'pending_approvals': overall['pendingApprovals'] ?? 0,
          'granted_today': 0, // Not provided by current RPC
          'not_granted_today': 0, // Not provided by current RPC
          'total_hours_today': 0.0, // Not provided by current RPC
          'total_amount_today': 0.0, // Not provided by current RPC
          'unpaid_amount': overall['unpaidAmount'] ?? 0.0,
          'department_breakdown': departments,
          'generated_at': DateTime.now().toIso8601String(),
        };
        
        dashboardSummary.value = AdminDashboardSummaryModel.fromMap(transformedData);
        _updateAnalytics();
      }
    } catch (e) {
      print('Error loading dashboard summary: $e');
    }
  }

  void _updateAnalytics() {
    final summary = dashboardSummary.value;
    if (summary != null) {
      totalActiveEmployees.value = summary.totalEmployees;
      totalCheckedInToday.value = summary.checkedInToday;
      totalPendingApprovals.value = summary.pendingApprovals;
      totalUnpaidAmount.value = summary.unpaidAmount;
    }
  }

  // Load filtered attendance data for table
  Future<void> loadAttendanceTableData() async {
    try {
      isTableLoading.value = true;

      // Determine date filter based on selected range
      String dateFilter = 'month'; // Default to last month to show data
      
      if (tableSelectedDateRange.value.isNotEmpty && 
          tableSelectedDateRange.value != 'All Time') {
        if (tableSelectedDateRange.value == 'Today') {
          dateFilter = 'today';
        } else if (tableSelectedDateRange.value == 'This Week') {
          dateFilter = 'week';
        } else if (tableSelectedDateRange.value == 'This Month') {
          dateFilter = 'month';
        }
      }
      
      // Status filter
      String statusFilter = 'all';
      if (tableSelectedStatus.value.isNotEmpty && 
          tableSelectedStatus.value != 'All Status') {
        statusFilter = tableSelectedStatus.value.toLowerCase();
      }
      
      // Department filter
      String departmentFilter = 'all';
      if (tableSelectedDepartment.value.isNotEmpty && 
          tableSelectedDepartment.value != 'All Departments') {
        departmentFilter = tableSelectedDepartment.value;
      }

      final response = await _supabase.rpc('get_admin_attendance_records', params: {
        'p_date_filter': dateFilter,
        'p_status_filter': statusFilter,
        'p_department_filter': departmentFilter,
        'p_limit': 50,
        'p_offset': 0,
      });

      if (response != null && response['success'] == true) {
        final attendanceData = response['data'] as List;
        final pagination = response['pagination'] ?? {};
        
        // Update total records from pagination info
        tableTotalRecords.value = pagination['total_records'] ?? attendanceData.length;
        
        // Transform the data to match the table format
        tableAttendanceList.value = attendanceData.map((record) {
          final employee = record['employee'] ?? {};
          final schedule = record['schedule'] ?? {};
          
          // Format times
          String formatTime(String? timeStr) {
            if (timeStr == null || timeStr.isEmpty) return '--';
            try {
              final dateTime = DateTime.parse(timeStr);
              return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
            } catch (e) {
              return timeStr;
            }
          }
          
          return {
            'attendance_id': record['attendance_id'], // Add the attendance ID
            'name': employee['full_name'] ?? 'Unknown',
            'avatar': (employee['full_name'] ?? 'U').split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
            'department': employee['department'] ?? 'Not Specified',
            'date': record['date'] ?? '',
            'checkIn': formatTime(record['check_in_time']),
            'checkOut': formatTime(record['check_out_time']),
            'scheduledIn': formatTime(schedule?['start_time']),
            'scheduledOut': formatTime(schedule?['end_time']),
            'status': record['status'] ?? 'Unknown',
            'workingHours': record['total_work_hours']?.toString() ?? '0',
            'overtime': record['overtime_hours']?.toString() ?? '0',
            'location': schedule?['location'] ?? record['check_in_address'] ?? 'Office',
          };
        }).toList();
      } else {
        // Fallback to empty list if response is invalid
        tableAttendanceList.value = [];
        print('Failed to load attendance data: ${response?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error loading attendance table data: $e');
      tableAttendanceList.value = [];
    } finally {
      isTableLoading.value = false;
    }
  }

  // Update attendance status
  Future<bool> updateAttendanceStatus({
    required String attendanceId,
    required String newStatus,
    String? adminNotes,
    String? reviewReason,
    double? calculatedAmount,
    double? adjustedHours,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('Error: No authenticated user found');
        return false;
      }

      final response = await _supabase.rpc('admin_update_attendance_status', params: {
        'p_attendance_id': attendanceId,
        'p_admin_id': currentUser.id,
        'p_new_status': newStatus,
        'p_admin_notes': adminNotes,
        'p_review_reason': reviewReason,
        'p_calculated_amount': calculatedAmount,
        'p_adjusted_hours': adjustedHours,
      });

      if (response != null && response['success'] == true) {
        // Refresh the attendance table data
        await loadAttendanceTableData();
        return true;
      } else {
        print('Failed to update attendance status: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Error updating attendance status: $e');
      return false;
    }
  }

  // Employee Management
  Future<void> loadAllEmployees() async {
    try {
      final response = await _supabase
          .from('my_users')
          .select('*')
          .eq('is_active', true)
          .order('full_name');

      final employees = (response as List)
          .map((emp) => UserModel.fromMap(emp))
          .toList();

      allEmployees.value = employees;
      filteredEmployees.value = employees;
      
      // Extract departments
      final deptSet = employees.map((emp) => emp.department).toSet();
      departments.value = ['All', ...deptSet.toList()];
      
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  void filterEmployees() {
    var filtered = allEmployees.where((employee) {
      final matchesSearch = employeeSearchQuery.value.isEmpty ||
          employee.fullName.toLowerCase().contains(employeeSearchQuery.value.toLowerCase()) ||
          employee.employeeId.toLowerCase().contains(employeeSearchQuery.value.toLowerCase()) ||
          employee.email.toLowerCase().contains(employeeSearchQuery.value.toLowerCase());

      final matchesDepartment = selectedDepartment.value == 'All' ||
          employee.department == selectedDepartment.value;

      return matchesSearch && matchesDepartment;
    }).toList();

    filteredEmployees.value = filtered;
  }

  // Attendance Management - Using new RPC functions
  Future<void> loadPendingAttendance() async {
    try {
      isLoading.value = true;
      
      final response = await _supabase.rpc('get_admin_attendance_records', params: {
        'p_date_filter': dateFilterType.value,
        'p_start_date': selectedStartDate.value?.toIso8601String().split('T')[0],
        'p_end_date': selectedEndDate.value?.toIso8601String().split('T')[0],
        'p_status_filter': 'pending',
        'p_department_filter': selectedDepartment.value == 'All' ? 'all' : selectedDepartment.value,
        'p_limit': 100,
        'p_offset': 0,
      });

      if (response != null && response['success'] == true) {
        final List<dynamic> attendanceData = response['data'] ?? [];
        final attendanceList = <AttendanceModel>[];
        
        // Clear previous raw data
        attendanceRawData.clear();
        
        for (final item in attendanceData) {
          try {
            // Store raw data for UI access
            attendanceRawData[item['attendance_id']] = Map<String, dynamic>.from(item);
            
            // Create AttendanceModel from the data
            final attendance = AttendanceModel.fromJson({
              'id': item['attendance_id'],
              'user_id': item['employee']['id'],
              'date': item['date'],
              'check_in_time': item['check_in_time'],
              'check_out_time': item['check_out_time'],
              'total_work_hours': item['total_work_hours'],
              'overtime_hours': item['overtime_hours'],
              'status': item['status'],
              'employee_notes': item['employee_notes'],
              'admin_notes': item['admin_notes'],
              'created_at': item['created_at'],
              'updated_at': item['updated_at'],
              'schedule_id': item['schedule']?['id'],
              'work_type': item['work_type'],
              'shift_type': item['shift_type'],
              'is_late': item['is_late'],
              'is_early_departure': item['is_early_departure'],
              'expected_hours': item['expected_hours'],
              'total_hours': item['total_hours'],
              'break_duration': item['break_duration'],
            });
            attendanceList.add(attendance);
          } catch (e) {
            print('Error parsing attendance item: $e');
            print('Item data: $item');
          }
        }
        
        pendingAttendance.value = attendanceList;
        totalPendingApprovals.value = attendanceList.length;
      } else {
        throw Exception(response?['message'] ?? 'Failed to load attendance records');
      }
    } catch (e) {
      print('Error loading pending attendance: $e');
      errorMessage.value = 'Failed to load pending attendance';
      pendingAttendance.value = [];
      totalPendingApprovals.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllAttendance() async {
    try {
      isLoading.value = true;
      
      final response = await _supabase.rpc('get_admin_attendance_records', params: {
        'p_date_filter': dateFilterType.value,
        'p_start_date': selectedStartDate.value?.toIso8601String().split('T')[0],
        'p_end_date': selectedEndDate.value?.toIso8601String().split('T')[0],
        'p_status_filter': 'all',
        'p_department_filter': selectedDepartment.value == 'All' ? 'all' : selectedDepartment.value,
        'p_limit': 100,
        'p_offset': 0,
      });

      if (response != null && response['success'] == true) {
        final List<dynamic> attendanceData = response['data'] ?? [];
        final attendanceList = <AttendanceModel>[];
        
        // Clear previous raw data
        attendanceRawData.clear();
        
        for (final item in attendanceData) {
          try {
            // Store raw data for UI access
            attendanceRawData[item['attendance_id']] = Map<String, dynamic>.from(item);
            
            // Create AttendanceModel from the data
            final attendance = AttendanceModel.fromJson({
              'id': item['attendance_id'],
              'user_id': item['employee']['id'],
              'date': item['date'],
              'check_in_time': item['check_in_time'],
              'check_out_time': item['check_out_time'],
              'total_work_hours': item['total_work_hours'],
              'overtime_hours': item['overtime_hours'],
              'status': item['status'],
              'employee_notes': item['employee_notes'],
              'admin_notes': item['admin_notes'],
              'created_at': item['created_at'],
              'updated_at': item['updated_at'],
              'schedule_id': item['schedule']?['id'],
              'work_type': item['work_type'],
              'shift_type': item['shift_type'],
              'is_late': item['is_late'],
              'is_early_departure': item['is_early_departure'],
              'expected_hours': item['expected_hours'],
              'total_hours': item['total_hours'],
              'break_duration': item['break_duration'],
            });
            attendanceList.add(attendance);
          } catch (e) {
            print('Error parsing attendance item: $e');
            print('Item data: $item');
          }
        }
        
        allAttendance.value = attendanceList;
      } else {
        throw Exception(response?['message'] ?? 'Failed to load attendance records');
      }
    } catch (e) {
      print('Error loading all attendance: $e');
      errorMessage.value = 'Failed to load attendance records';
      allAttendance.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // New method to approve/reject attendance
  Future<bool> reviewAttendance({
    required String attendanceId,
    required String action, // 'approve' or 'reject'
    String? adminNotes,
    String? reviewReason,
  }) async {
    try {
      // Get current admin user ID (you might need to adjust this based on your auth system)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      final response = await _supabase.rpc('admin_review_attendance', params: {
        'p_attendance_id': attendanceId,
        'p_admin_id': currentUser.id,
        'p_action': action,
        'p_admin_notes': adminNotes,
        'p_review_reason': reviewReason,
      });

      if (response != null && response['success'] == true) {
        // Refresh attendance data
        refreshAttendanceData();
        return true;
      } else {
        throw Exception(response?['message'] ?? 'Failed to review attendance');
      }
    } catch (e) {
      print('Error reviewing attendance: $e');
      errorMessage.value = 'Failed to review attendance: $e';
      return false;
    }
  }

  // Helper method to get employee data for an attendance record
  Map<String, dynamic>? getEmployeeDataForAttendance(String attendanceId) {
    final rawData = attendanceRawData[attendanceId];
    return rawData?['employee'];
  }

  // Helper method to get schedule data for an attendance record
  Map<String, dynamic>? getScheduleDataForAttendance(String attendanceId) {
    final rawData = attendanceRawData[attendanceId];
    return rawData?['schedule'];
  }

  // Helper method to get status info for an attendance record
  Map<String, dynamic>? getStatusInfoForAttendance(String attendanceId) {
    final rawData = attendanceRawData[attendanceId];
    return rawData?['status_info'];
  }

  // Date filter methods
  void setDateFilterToday() {
    dateFilterType.value = 'today';
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    refreshAttendanceData();
  }

  void setDateFilterRange(DateTime startDate, DateTime endDate) {
    dateFilterType.value = 'range';
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    refreshAttendanceData();
  }

  void setDateFilterAll() {
    dateFilterType.value = 'all';
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    refreshAttendanceData();
  }

  void refreshAttendanceData() async {
    switch (selectedAttendanceFilter.value) {
      case 'pending':
        await loadPendingAttendance();
        break;
      case 'all':
        await loadAllAttendance();
        break;
      default:
        await loadPendingAttendance();
    }
  }

  Future<void> loadAttendanceByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .rpc('get_attendance_by_date_range', params: {
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
          });

      if (response != null) {
        final attendanceList = (response as List)
            .map((att) => AttendanceModel.fromJson(att))
            .toList();
        allAttendance.value = attendanceList;
      }
    } catch (e) {
      print('Error loading attendance by date range: $e');
    }
  }

  Future<bool> bulkUpdateAttendanceStatus({
    required List<String> attendanceIds,
    required String status,
    required String adminId,
    String? reviewNotes,
    String? reviewReason,
  }) async {
    try {
      final response = await _supabase.rpc('bulk_update_attendance_status', 
        params: {
          'p_attendance_ids': attendanceIds,
          'p_status': status,
          'p_reviewed_by': adminId,
          'p_admin_notes': reviewNotes,
          'p_review_reason': reviewReason,
        }
      );

      if (response['success'] == true) {
        await loadPendingAttendance(); // Refresh the list
        await loadDashboardSummary(); // Update dashboard
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating attendance status: $e');
      return false;
    }
  }

  // Individual attendance approval/rejection methods
  Future<bool> approveAttendance(String attendanceId, {String? notes}) async {
    try {
      await _supabase
          .from('attendance')
          .update({
            'status': 'granted',
            'is_approved_for_payment': true,
            'approved_by_admin_id': currentAdminId, // You'll need to set this
            'approval_date_time': DateTime.now().toIso8601String(),
            'admin_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('attendance_id', attendanceId);

      await loadPendingAttendance(); // Refresh pending list
      await loadAllAttendance(); // Refresh all attendance
      return true;
    } catch (e) {
      print('Error approving attendance: $e');
      errorMessage.value = 'Failed to approve attendance';
      return false;
    }
  }

  Future<bool> rejectAttendance(String attendanceId, {String? reason}) async {
    try {
      await _supabase
          .from('attendance')
          .update({
            'status': 'not_granted',
            'is_approved_for_payment': false,
            'approved_by_admin_id': currentAdminId, // You'll need to set this
            'approval_date_time': DateTime.now().toIso8601String(),
            'admin_notes': reason ?? 'Rejected by admin',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('attendance_id', attendanceId);

      await loadPendingAttendance(); // Refresh pending list
      await loadAllAttendance(); // Refresh all attendance
      return true;
    } catch (e) {
      print('Error rejecting attendance: $e');
      errorMessage.value = 'Failed to reject attendance';
      return false;
    }
  }

  // Helper method to get current admin ID (you might want to get this from auth or user session)
  String get currentAdminId => 'admin_001'; // Replace with actual admin ID from session

  // Schedule Management
  Future<void> loadActiveSchedules() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final response = await _supabase
          .from('employee_schedules')
          .select('''
            *,
            assigned_user:assigned_user_id(full_name, employee_id),
            actual_user:actual_user_id(full_name, employee_id)
          ''')
          .gte('start_date_time', DateTime.now().toIso8601String())
          .lte('start_date_time', tomorrow.toIso8601String())
          .eq('is_active', true)
          .order('start_date_time');

      final schedules = (response as List)
          .map((schedule) => ScheduleModel.fromMap(schedule))
          .toList();

      activeSchedules.value = schedules;
    } catch (e) {
      print('Error loading active schedules: $e');
    }
  }

  // Audit Logs
  Future<void> loadRecentAuditLogs({int limit = 50}) async {
    try {
      // TODO: Implement audit logs when attendance_audit_log table is created
      print('Audit logs feature not implemented yet - table attendance_audit_log does not exist');
      auditLogs.value = [];
    } catch (e) {
      print('Error loading audit logs: $e');
      auditLogs.value = [];
    }
  }

  // Real-time event handlers
  void _handleAttendanceChange(PostgresChangePayload payload) {
    // Refresh attendance data when changes occur
    loadPendingAttendance();
    loadDashboardSummary();
  }

  void _handleUserChange(PostgresChangePayload payload) {
    // Refresh employee data when changes occur
    loadAllEmployees();
  }

  void _handleScheduleChange(PostgresChangePayload payload) {
    // Refresh schedule data when changes occur
    loadActiveSchedules();
  }

  @override
  void onClose() {
    // Close Supabase subscriptions
    _supabase.removeAllChannels();
    super.onClose();
  }

  // Utility methods
  String getEmployeeStatusColor(UserModel employee) {
    if (!employee.isActive) return 'inactive';
    // You can add more logic here based on attendance, etc.
    return 'active';
  }

  String getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'warning';
      case 'granted':
      case 'approved':
        return 'success';
      case 'not_granted':
      case 'rejected':
        return 'error';
      default:
        return 'info';
    }
  }

  double calculateAttendanceApprovalRate() {
    if (allAttendance.isEmpty) return 0.0;
    final approved = allAttendance.where((att) => att.status == 'granted').length;
    return (approved / allAttendance.length) * 100;
  }

  // Load summary data based on selected time range
  Future<void> loadSummaryData() async {
    try {
      isLoading.value = true;
      
      // This method will be called when filters change
      // For now, it just refreshes existing data
      // In a real implementation, you would fetch data based on selectedTimeRange
      
      print('Loading summary data for: ${selectedTimeRange.value}');
      
      // Simulate loading delay
      await Future.delayed(Duration(milliseconds: 500));
      
      // Refresh existing data
      await loadInitialData();
      
    } catch (e) {
      print('Error loading summary data: $e');
      errorMessage.value = 'Failed to load summary data';
    } finally {
      isLoading.value = false;
    }
  }

  // Admin logout method
  Future<void> onLogoutPressed() async {
    try {
      // Show loading indicator
      EasyLoading.show(status: "Logging out...");
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear any cached admin data
      allEmployees.clear();
      filteredEmployees.clear();
      pendingAttendance.clear();
      allAttendance.clear();
      auditLogs.clear();
      attendanceRawData.clear();
      activeSchedules.clear();
      coverageRequests.clear();
      paymentRecords.clear();
      
      // Reset filters and selections
      employeeSearchQuery.value = '';
      selectedDepartment.value = 'All';
      selectedAttendanceFilter.value = 'pending';
      selectedStartDate.value = null;
      selectedEndDate.value = null;
      dateFilterType.value = 'today';
      dashboardSummary.value = null;
      
      // Dismiss loading
      EasyLoading.dismiss();
      
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Show success message
        Get.snackbar(
          'Success',
          'Logged out successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstant.successColor,
          colorText: Colors.white,
          borderRadius: 15,
          margin: EdgeInsets.all(15),
        );
        
        // Navigate to welcome screen and clear navigation stack
        Get.offAllNamed('/welcome');
      });
      
    } catch (e) {
      EasyLoading.dismiss();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Error',
          'Failed to logout. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
          borderRadius: 15,
          margin: EdgeInsets.all(15),
        );
      });
      
      print('Admin logout error: $e');
    }
  }
}
