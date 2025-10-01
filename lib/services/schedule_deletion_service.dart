// ignore_for_file: file_names
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class ScheduleDeletionService extends GetxService {
  static ScheduleDeletionService get to => Get.find();
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Preview schedule deletion without actually deleting
  Future<Map<String, dynamic>> previewScheduleDeletion({
    int hoursBack = 24,
  }) async {
    try {
      print('DEBUG: Previewing schedule deletion for last $hoursBack hours');
      
      final response = await _supabase.rpc('preview_schedule_deletion', params: {
        'p_hours_back': hoursBack,
      });

      print('DEBUG: Preview response: $response');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['preview_data'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('DEBUG: Error previewing schedule deletion: $e');
      return {
        'success': false,
        'error': 'Failed to preview schedule deletion: $e',
      };
    }
  }

  /// Get detailed list of schedules for deletion
  Future<Map<String, dynamic>> getSchedulesForDeletion({
    int hoursBack = 24,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      print('DEBUG: Getting schedules for deletion - hours: $hoursBack, limit: $limit, offset: $offset');
      
      final response = await _supabase.rpc('get_schedules_for_deletion', params: {
        'p_hours_back': hoursBack,
        'p_limit': limit,
        'p_offset': offset,
      });

      print('DEBUG: Schedules response: $response');

      if (response['success'] == true) {
        return {
          'success': true,
          'schedules': response['schedules'] ?? [],
          'pagination': response['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('DEBUG: Error getting schedules for deletion: $e');
      return {
        'success': false,
        'error': 'Failed to get schedules for deletion: $e',
      };
    }
  }

  /// Safely delete schedules with optional backup
  Future<Map<String, dynamic>> deleteSchedules({
    int hoursBack = 24,
    bool createBackup = true,
    String executedBy = 'system',
  }) async {
    try {
      print('DEBUG: Deleting schedules - hours: $hoursBack, backup: $createBackup, executedBy: $executedBy');
      
      final response = await _supabase.rpc('safe_delete_schedules', params: {
        'p_hours_back': hoursBack,
        'p_create_backup': createBackup,
        'p_executed_by': executedBy,
      });

      print('DEBUG: Deletion response: $response');

      if (response['success'] == true) {
        return {
          'success': true,
          'deletion_summary': response['deletion_summary'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('DEBUG: Error deleting schedules: $e');
      return {
        'success': false,
        'error': 'Failed to delete schedules: $e',
      };
    }
  }

  /// Restore schedules from backup
  Future<Map<String, dynamic>> restoreSchedulesFromBackup({
    int hoursBack = 24,
    String executedBy = 'system',
  }) async {
    try {
      print('DEBUG: Restoring schedules from backup - hours: $hoursBack, executedBy: $executedBy');
      
      final response = await _supabase.rpc('restore_schedules_from_backup', params: {
        'p_hours_back': hoursBack,
        'p_executed_by': executedBy,
      });

      print('DEBUG: Restoration response: $response');

      if (response['success'] == true) {
        return {
          'success': true,
          'restoration_summary': response['restoration_summary'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('DEBUG: Error restoring schedules: $e');
      return {
        'success': false,
        'error': 'Failed to restore schedules: $e',
      };
    }
  }

  /// Get deletion log history
  Future<Map<String, dynamic>> getDeletionLog({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('DEBUG: Getting deletion log - limit: $limit, offset: $offset');
      
      final response = await _supabase.rpc('get_deletion_log', params: {
        'p_limit': limit,
        'p_offset': offset,
      });

      print('DEBUG: Deletion log response: $response');

      if (response['success'] == true) {
        return {
          'success': true,
          'logs': response['logs'] ?? [],
          'pagination': response['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('DEBUG: Error getting deletion log: $e');
      return {
        'success': false,
        'error': 'Failed to get deletion log: $e',
      };
    }
  }

  /// Test all RPC functions
  Future<Map<String, dynamic>> testAllFunctions() async {
    try {
      print('DEBUG: Testing all schedule deletion RPC functions');
      
      final results = <String, dynamic>{};
      
      // Test preview function
      final previewResult = await previewScheduleDeletion(hoursBack: 24);
      results['preview_test'] = previewResult;
      
      // Test get schedules function
      final schedulesResult = await getSchedulesForDeletion(hoursBack: 24, limit: 10);
      results['schedules_test'] = schedulesResult;
      
      // Test deletion log function
      final logResult = await getDeletionLog(limit: 5);
      results['log_test'] = logResult;
      
      // Check if all tests passed
      final allPassed = results.values.every((result) => 
        result is Map<String, dynamic> && result['success'] == true);
      
      return {
        'success': allPassed,
        'test_results': results,
        'message': allPassed ? 'All RPC functions working correctly' : 'Some RPC functions failed',
      };
    } catch (e) {
      print('DEBUG: Error testing RPC functions: $e');
      return {
        'success': false,
        'error': 'Failed to test RPC functions: $e',
      };
    }
  }
}
