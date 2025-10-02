import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for fetching attendance history with pagination and filtering
class AttendanceHistoryService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get current logged in user ID for debugging
  static String? getCurrentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    print('DEBUG: Current user ID: ${userId ?? "NOT LOGGED IN"}');
    return userId;
  }

  /// Fetch user's attendance history with pagination and filters
  static Future<Map<String, dynamic>> getUserAttendanceHistory({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('DEBUG: Fetching attendance history for user: $userId');
      print('DEBUG: Filter - status: $status, limit: $limit, offset: $offset');
      
      // Use direct query for attendance data
      return await _directQueryAttendance(
        userId: userId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('ERROR fetching attendance history: $e');
      return {
        'attendance_records': [],
        'total_count': 0,
        'limit': limit,
        'offset': offset,
        'has_more': false,
        'error': e.toString(),
      };
    }
  }

  /// Direct query to fetch attendance records from database
  static Future<Map<String, dynamic>> _directQueryAttendance({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('DEBUG: ========== ATTENDANCE QUERY DEBUG ==========');
      print('DEBUG: Querying attendance for user_id: $userId');
      print('DEBUG: Status filter: ${status ?? "NONE (all statuses)"}');
      print('DEBUG: Limit: $limit, Offset: $offset');

      // Build query with filters - using actual table schema
      var queryBuilder = _supabase
          .from('attendance')
          .select('''
            id,
            user_id,
            schedule_id,
            date,
            check_in_time,
            check_out_time,
            check_in_location_lat,
            check_in_location_lng,
            check_out_location_lat,
            check_out_location_lng,
            check_in_address,
            check_out_address,
            location,
            latitude,
            longitude,
            status,
            total_work_hours,
            total_break_hours,
            net_work_hours,
            overtime_hours,
            total_hours,
            break_duration,
            expected_hours,
            is_late,
            is_early_departure,
            break_exceeded,
            work_type,
            shift_type,
            employee_notes,
            admin_notes,
            reviewed_by,
            reviewed_at,
            payment_status,
            total_amount,
            created_at,
            updated_at,
            schedule:employee_schedules(
              id,
              title,
              description,
              start_date_time,
              end_date_time,
              location,
              department
            )
          ''')
          .eq('user_id', userId);

      // Apply date filter only if explicitly provided
      if (startDate != null && endDate != null) {
        print('DEBUG: Applying date filter - start: $startDate, end: $endDate');
        queryBuilder = queryBuilder
            .gte('date', startDate.toIso8601String().split('T')[0])
            .lte('date', endDate.toIso8601String().split('T')[0]);
      } else {
        print('DEBUG: No date filter applied - fetching all records for user');
      }

      // Apply status filter if provided
      if (status != null && status.isNotEmpty) {
        print('DEBUG: Applying status filter: $status');
        queryBuilder = queryBuilder.eq('status', status);
      }

      final response = await queryBuilder
          .order('date', ascending: false)
          .order('check_in_time', ascending: false)
          .range(offset, offset + limit - 1);
      
      print('DEBUG: Query executed successfully!');
      print('DEBUG: Response count: ${response.length}');
      print('DEBUG: Response type: ${response.runtimeType}');
      
      if (response.isEmpty) {
        print('DEBUG: ⚠️ NO RECORDS FOUND!');
        print('DEBUG: Possible reasons:');
        print('DEBUG:   - User ID mismatch (check if user is logged in)');
        print('DEBUG:   - RLS policies blocking access');
        print('DEBUG:   - No attendance records for this user in database');
      } else {
        print('DEBUG: ✅ Found ${response.length} attendance records');
        print('DEBUG: First record date: ${response[0]['date']}');
        print('DEBUG: First record status: ${response[0]['status']}');
      }

      // If we got a full page, there might be more
      final hasMoreRecords = response.length >= limit;

      print('DEBUG: Has more records: $hasMoreRecords');

      // Transform response to standardized format
      final records = (response as List).map((record) {
        final scheduleData = record['schedule'] as Map<String, dynamic>?;
        
        // Calculate work duration in hours if we have both check-in and check-out
        double? workDurationHours;
        if (record['check_in_time'] != null && record['check_out_time'] != null) {
          try {
            final checkIn = DateTime.parse(record['check_in_time']);
            final checkOut = DateTime.parse(record['check_out_time']);
            final duration = checkOut.difference(checkIn);
            workDurationHours = duration.inMinutes / 60.0;
          } catch (e) {
            print('DEBUG: Error calculating duration: $e');
          }
        }
        
        return {
          'id': record['id'],
          'schedule_id': record['schedule_id'],
          'user_id': record['user_id'],
          'date': record['date'],
          'check_in_time': record['check_in_time'],
          'check_out_time': record['check_out_time'],
          'check_in_location_lat': record['check_in_location_lat'],
          'check_in_location_lng': record['check_in_location_lng'],
          'check_out_location_lat': record['check_out_location_lat'],
          'check_out_location_lng': record['check_out_location_lng'],
          'check_in_address': record['check_in_address'],
          'check_out_address': record['check_out_address'],
          'location': record['location'],
          'latitude': record['latitude'],
          'longitude': record['longitude'],
          'status': record['status'],
          'total_work_hours': record['total_work_hours'] ?? record['net_work_hours'] ?? 0.0,
          'total_break_hours': record['total_break_hours'] ?? 0.0,
          'net_work_hours': record['net_work_hours'] ?? 0.0,
          'overtime_hours': record['overtime_hours'] ?? 0.0,
          'work_duration_hours': workDurationHours ?? (record['total_work_hours'] ?? 0.0),
          'expected_hours': record['expected_hours'] ?? 8.0,
          'is_late': record['is_late'] ?? false,
          'is_early_departure': record['is_early_departure'] ?? false,
          'break_exceeded': record['break_exceeded'] ?? false,
          'work_type': record['work_type'],
          'shift_type': record['shift_type'],
          'employee_notes': record['employee_notes'],
          'admin_notes': record['admin_notes'],
          'reviewed_by': record['reviewed_by'],
          'reviewed_at': record['reviewed_at'],
          'payment_status': record['payment_status'],
          'total_amount': record['total_amount'],
          'created_at': record['created_at'],
          'updated_at': record['updated_at'],
          'schedule': scheduleData != null ? {
            'id': scheduleData['id'],
            'title': scheduleData['title'],
            'description': scheduleData['description'],
            'start_date_time': scheduleData['start_date_time'],
            'end_date_time': scheduleData['end_date_time'],
            'location': scheduleData['location'],
            'department': scheduleData['department'],
          } : null,
        };
      }).toList();

      return {
        'attendance_records': records,
        'total_count': offset + records.length + (hasMoreRecords ? 1 : 0),
        'limit': limit,
        'offset': offset,
        'has_more': hasMoreRecords,
      };
    } catch (e) {
      print('ERROR in direct query: $e');
      return {
        'attendance_records': [],
        'total_count': 0,
        'limit': limit,
        'offset': offset,
        'has_more': false,
        'error': e.toString(),
      };
    }
  }
}

