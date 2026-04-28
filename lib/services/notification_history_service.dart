import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class NotificationHistoryService extends GetxService {
  static NotificationHistoryService get to => Get.find();
  
  SupabaseClient get _supabase {
    final client = SupabaseService.to.client;
    if (client == null) {
      throw Exception('Supabase client not initialized');
    }
    return client;
  }
  
  // Observable lists
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  
  // Pagination
  final int pageSize = 20;
  int currentPage = 0;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    // Load initial notifications
    fetchNotifications();
    // Subscribe to realtime updates
    subscribeToNotifications();
    // Fetch unread count
    fetchUnreadCount();
  }

  /// Fetch notifications with pagination
  Future<List<NotificationModel>> fetchNotifications({
    bool refresh = false,
    int? limit,
  }) async {
    try {
      if (refresh) {
        currentPage = 0;
        hasMore = true;
        notifications.clear();
      }

      if (!hasMore && !refresh) {
        return notifications;
      }

      isLoading.value = true;

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Use RPC function to bypass schema cache issues
      try {
        final response = await _supabase.rpc(
          'get_user_notifications',
          params: {
            'p_user_id': user.id,
            'p_limit_count': pageSize,
            'p_offset_count': currentPage * pageSize,
          },
        );

        final List<NotificationModel> fetchedNotifications = (response as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        if (refresh) {
          notifications.value = fetchedNotifications;
        } else {
          notifications.addAll(fetchedNotifications);
        }

        hasMore = fetchedNotifications.length == pageSize;
        currentPage++;

        return notifications;
      } catch (e) {
        print('RPC method failed, trying direct table access: $e');
        
        // Fallback to direct table access with retry logic
        int retries = 3;
        while (retries > 0) {
          try {
            final response = await _supabase
                .from('notifications')
                .select()
                .eq('user_id', user.id)
                .isFilter('deleted_at', null)
                .order('created_at', ascending: false)
                .range(
                  currentPage * pageSize,
                  (currentPage + 1) * pageSize - 1,
                );

            final List<NotificationModel> fetchedNotifications = (response as List)
                .map((json) => NotificationModel.fromJson(json))
                .toList();

            if (refresh) {
              notifications.value = fetchedNotifications;
            } else {
              notifications.addAll(fetchedNotifications);
            }

            hasMore = fetchedNotifications.length == pageSize;
            currentPage++;

            return notifications;
          } catch (e) {
            if (e.toString().contains('PGRST205') && retries > 1) {
              print('Schema cache issue, retrying in 2 seconds... ($retries retries left)');
              await Future.delayed(Duration(seconds: 2));
              retries--;
              continue;
            }
            rethrow;
          }
        }
      }
      
      throw Exception('Failed to fetch notifications after retries');
    } catch (e) {
      print('Error fetching notifications: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch unread notifications only
  Future<List<NotificationModel>> fetchUnreadNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Get unread notification count
  Future<int> fetchUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final result = await _supabase.rpc('get_unread_notification_count');
      
      unreadCount.value = result as int;
      return unreadCount.value;
    } catch (e) {
      print('Error fetching unread count: $e');
      unreadCount.value = 0;
      return 0; // Return 0 instead of throwing
    }
  }

  /// Mark single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final result = await _supabase.rpc(
        'mark_notification_as_read',
        params: {'notification_id': notificationId},
      );

      if (result == true) {
        // Update local state
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
            status: 'read',
          );
          notifications.refresh();
        }
        
        // Update unread count
        if (unreadCount.value > 0) {
          unreadCount.value--;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final result = await _supabase.rpc('mark_all_notifications_as_read');
      
      final affectedRows = result as int;
      
      if (affectedRows > 0) {
        // Update local state
        notifications.value = notifications.map((n) {
          if (!n.isRead) {
            return n.copyWith(
              isRead: true,
              readAt: DateTime.now(),
              status: 'read',
            );
          }
          return n;
        }).toList();
        
        unreadCount.value = 0;
      }
      
      return affectedRows;
    } catch (e) {
      print('Error marking all as read: $e');
      return 0;
    }
  }

  /// Delete notification (soft delete)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      // Remove from local state
      notifications.removeWhere((n) => n.id == notificationId);
      
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('type', type)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications by type: $e');
      rethrow;
    }
  }

  /// Get notifications by schedule ID
  Future<List<NotificationModel>> getNotificationsBySchedule(String scheduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('schedule_id', scheduleId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications by schedule: $e');
      rethrow;
    }
  }

  /// Subscribe to realtime notification updates
  void subscribeToNotifications() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .listen(
            (data) {
              print('Realtime notification update received');
              
              // Refresh notifications
              fetchNotifications(refresh: true);
              fetchUnreadCount();
            },
            onError: (error) {
              print('Realtime subscription error: $error');
              // Don't crash the app, just log the error
            },
          );
    } catch (e) {
      print('Error setting up realtime subscription: $e');
      // Don't crash the app, just log the error
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoading.value) return;
    await fetchNotifications();
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await fetchNotifications(refresh: true);
    await fetchUnreadCount();
  }

  /// Clear all notifications (admin function)
  Future<void> clearAll() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id);

      notifications.clear();
      unreadCount.value = 0;
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'total': 0,
          'unread': 0,
          'read': 0,
          'schedule': 0,
          'general': 0,
        };
      }

      final allNotifications = await _supabase
          .from('notifications')
          .select('type, is_read')
          .eq('user_id', user.id)
          .isFilter('deleted_at', null);

      final List<Map<String, dynamic>> data = (allNotifications as List)
          .cast<Map<String, dynamic>>();

      return {
        'total': data.length,
        'unread': data.where((n) => n['is_read'] == false).length,
        'read': data.where((n) => n['is_read'] == true).length,
        'schedule': data.where((n) => n['type']?.toString().contains('schedule') ?? false).length,
        'general': data.where((n) => n['type'] == 'general').length,
      };
    } catch (e) {
      print('Error fetching notification stats: $e');
      return {};
    }
  }
}

