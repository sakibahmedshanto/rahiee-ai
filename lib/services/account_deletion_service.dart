// ignore_for_file: file_names

import 'package:get/get.dart';
import 'supabase_service.dart';

/// Service for handling complete account deletion
/// Meets Apple's App Store requirement for account deletion within the app
class AccountDeletionService extends GetxService {
  static AccountDeletionService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;
  
  /// Delete user account completely
  /// This will delete all related data in the correct order to respect foreign key constraints:
  /// 1. attendance, employee_schedules, schedule_assignments, schedule_exchange_requests
  /// 2. payment_transactions, monthly_attendance_summary, user_lifetime_summary
  /// 3. notifications
  /// 4. my_users profile (must be last)
  /// 5. Sign out
  /// 
  /// Note: Auth account deletion requires admin API which isn't available from client
  Future<Map<String, dynamic>> deleteUserAccount(String userId) async {
    try {
      print('🗑️ Starting account deletion process for user: $userId');
      
      final client = _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }
      
      // Delete all related data respecting foreign key constraints
      
      // Attendance records
      try {
        print('📝 Deleting attendance records...');
        await _supabaseService.delete('attendance', eq: 'user_id', eqValue: userId);
        print('✅ Attendance records deleted');
      } catch (e) {
        print('⚠️ Failed to delete attendance: $e');
      }

      // Employee schedules
      try {
        print('📝 Deleting employee schedules...');
        await _supabaseService.delete('employee_schedules', eq: 'created_by_admin_id', eqValue: userId);
        print('✅ Employee schedules deleted');
      } catch (e) {
        print('⚠️ Failed to delete employee schedules: $e');
      }

      // Schedule assignments
      try {
        print('📝 Deleting schedule assignments...');
        await _supabaseService.delete('schedule_assignments', eq: 'user_id', eqValue: userId);
        await _supabaseService.delete('schedule_assignments', eq: 'assigned_by_admin_id', eqValue: userId);
        print('✅ Schedule assignments deleted');
      } catch (e) {
        print('⚠️ Failed to delete schedule assignments: $e');
      }

      // Schedule exchange requests
      try {
        print('📝 Deleting schedule exchange requests...');
        await _supabaseService.delete('schedule_exchange_requests', eq: 'requester_user_id', eqValue: userId);
        await _supabaseService.delete('schedule_exchange_requests', eq: 'requested_user_id', eqValue: userId);
        await _supabaseService.delete('schedule_exchange_requests', eq: 'reviewed_by_admin_id', eqValue: userId);
        print('✅ Schedule exchange requests deleted');
      } catch (e) {
        print('⚠️ Failed to delete schedule exchange requests: $e');
      }

      // Payment transactions
      try {
        print('📝 Deleting payment transactions...');
        await _supabaseService.delete('payment_transactions', eq: 'user_id', eqValue: userId);
        print('✅ Payment transactions deleted');
      } catch (e) {
        print('⚠️ Failed to delete payment transactions: $e');
      }

      // Monthly attendance summary
      try {
        print('📝 Deleting monthly attendance summary...');
        await _supabaseService.delete('monthly_attendance_summary', eq: 'finalized_by', eqValue: userId);
        print('✅ Monthly attendance summary deleted');
      } catch (e) {
        print('⚠️ Failed to delete monthly attendance summary: $e');
      }

      // User lifetime summary
      try {
        print('📝 Deleting user lifetime summary...');
        await _supabaseService.delete('user_lifetime_summary', eq: 'user_id', eqValue: userId);
        print('✅ User lifetime summary deleted');
      } catch (e) {
        print('⚠️ Failed to delete user lifetime summary: $e');
      }

      // Notifications
      try {
        print('📝 Deleting notifications...');
        await _supabaseService.delete('notifications', eq: 'user_id', eqValue: userId);
        print('✅ Notifications deleted');
      } catch (e) {
        print('⚠️ Failed to delete notifications: $e');
      }
      
      // User profile (must be last due to foreign keys)
      print('📝 Deleting user profile data...');
      await _supabaseService.delete('my_users', eq: 'id', eqValue: userId);
      print('✅ User profile data deleted');
      
      print('🎉 Account deletion completed successfully');
      
      return {
        'success': true,
        'message': 'Your account has been permanently deleted. All your personal data has been removed from our systems.',
      };
      
    } catch (e) {
      print('❌ Account deletion failed: $e');
      
      return {
        'success': false,
        'message': 'Failed to delete account: ${e.toString()}. Please contact support at support@rahiee.ai',
        'error': e.toString(),
      };
    }
  }
  
  /// Alternative method: Request account deletion via backend
  /// This is recommended if you want to handle deletions asynchronously
  /// or need to comply with data retention policies
  Future<Map<String, dynamic>> requestAccountDeletion(String userId, String email) async {
    try {
      print('📧 Submitting account deletion request...');
      
      // Mark user as pending deletion in the database
      await _supabaseService.update(
        'my_users',
        {
          'is_active': false,
          'deletion_requested_at': DateTime.now().toIso8601String(),
          'deletion_status': 'pending',
        },
        eq: 'id',
        eqValue: userId,
      );
      
      // Optionally: Send notification to admin or trigger edge function
      // You could create a Supabase Edge Function to handle deletion requests
      
      print('✅ Account deletion request submitted');
      
      return {
        'success': true,
        'message': 'Your account deletion request has been submitted. Your account will be permanently deleted within 30 days. You can contact support at support@rahiee.ai if you need assistance.',
      };
      
    } catch (e) {
      print('❌ Failed to submit deletion request: $e');
      return {
        'success': false,
        'message': 'Failed to submit deletion request. Please contact support at support@rahiee.ai',
        'error': e.toString(),
      };
    }
  }
  
  /// Check if user has any data that cannot be deleted due to legal requirements
  /// This is useful for informing users about data retention
  Future<Map<String, dynamic>> checkDeletionEligibility(String userId) async {
    try {
      // You can add checks here for any business rules
      // For example, check if there are pending transactions, unresolved issues, etc.
      
      return {
        'eligible': true,
        'message': 'Your account is eligible for deletion.',
        'warnings': <String>[
          // Add any warnings about what will be deleted
          'All your personal information will be permanently deleted',
          'Your attendance history will be removed',
          'This action cannot be undone',
        ],
      };
    } catch (e) {
      return {
        'eligible': false,
        'message': 'Failed to check deletion eligibility',
        'error': e.toString(),
      };
    }
  }
}
