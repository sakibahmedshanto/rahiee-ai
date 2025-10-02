import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/attendance_history_service.dart';

/// Controller for managing attendance history
class AttendanceHistoryController extends GetxController {
  // Observable variables
  final RxList<Map<String, dynamic>> attendanceRecords = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt offset = 0.obs;
  final RxString selectedStatus = ''.obs; // '' means all
  
  // Constants
  final int limit = 20;
  
  // User ID
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
  
  @override
  void onInit() {
    super.onInit();
    print('DEBUG: AttendanceHistoryController initialized');
    print('DEBUG: Current user ID: $currentUserId');
    loadAttendanceHistory();
  }
  
  /// Load attendance history with pagination
  Future<void> loadAttendanceHistory() async {
    if (isLoading.value || !hasMore.value) {
      print('DEBUG: Skipping load - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}');
      return;
    }
    
    if (currentUserId == null) {
      print('DEBUG: ❌ User not authenticated');
      Get.snackbar(
        'Error', 
        'User not authenticated. Please log in.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    print('DEBUG: ========== CONTROLLER LOADING ATTENDANCE ==========');
    print('DEBUG: User ID: $currentUserId');
    print('DEBUG: Selected status: ${selectedStatus.value.isEmpty ? "ALL" : selectedStatus.value}');
    print('DEBUG: Current offset: ${offset.value}');
    print('DEBUG: Current records count: ${attendanceRecords.length}');
    
    isLoading.value = true;
    
    try {
      final result = await AttendanceHistoryService.getUserAttendanceHistory(
        userId: currentUserId!,
        status: selectedStatus.value.isEmpty ? null : selectedStatus.value,
        limit: limit,
        offset: offset.value,
      );
      
      print('DEBUG: Service returned result: ${result.keys.toList()}');
      
      if (result.containsKey('error')) {
        print('DEBUG: ❌ Error in result: ${result['error']}');
        throw Exception(result['error']);
      }
      
      final records = List<Map<String, dynamic>>.from(result['attendance_records'] ?? []);
      
      print('DEBUG: Loaded ${records.length} new attendance records');
      print('DEBUG: Total count from server: ${result['total_count']}');
      print('DEBUG: Has more: ${result['has_more']}');
      
      if (records.isEmpty && offset.value == 0) {
        print('DEBUG: ℹ️ No attendance records found for this user');
        print('DEBUG: 💡 User might not have any attendance records yet');
        print('DEBUG: 💡 Or RLS policies might be blocking access');
      } else if (records.isNotEmpty) {
        print('DEBUG: ✅ Successfully loaded records');
        print('DEBUG: Sample record IDs: ${records.take(3).map((r) => r['id']).toList()}');
      }
      
      attendanceRecords.addAll(records);
      hasMore.value = result['has_more'] ?? false;
      offset.value += limit;
      
      print('DEBUG: Total records now: ${attendanceRecords.length}');
    } catch (e, stackTrace) {
      print('DEBUG: ❌ Exception loading attendance: $e');
      print('DEBUG: Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load attendance history. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('DEBUG: Loading completed. isLoading: ${isLoading.value}');
    }
  }
  
  /// Apply filter and reload data
  void applyFilter(String? status) {
    selectedStatus.value = status ?? '';
    resetAndLoad();
  }
  
  /// Reset pagination and reload
  void resetAndLoad() {
    attendanceRecords.clear();
    offset.value = 0;
    hasMore.value = true;
    loadAttendanceHistory();
  }
  
  /// Refresh data (for pull-to-refresh)
  Future<void> refreshData() async {
    attendanceRecords.clear();
    offset.value = 0;
    hasMore.value = true;
    await loadAttendanceHistory();
  }
  
  /// Get filter display name
  String get filterDisplayName {
    switch (selectedStatus.value) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'pending_checkout':
        return 'Pending Checkout';
      case 'granted':
        return 'Granted';
      case 'not_granted':
        return 'Not Granted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'unusual':
        return 'Unusual';
      case 'appealed':
        return 'Appealed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'All';
    }
  }
}

