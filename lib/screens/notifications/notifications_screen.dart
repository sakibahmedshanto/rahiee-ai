import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/notification_history_service.dart';
import '../../models/notification_model.dart';
import '../../utils/app_constant.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationHistoryService _notificationService;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _notificationService = Get.find<NotificationHistoryService>();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotificationsTab(),
                _buildUnreadNotificationsTab(),
                _buildReadNotificationsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstant.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.notifications_active, size: 28),
          const SizedBox(width: 8),
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Obx(() => _notificationService.unreadCount.value > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_notificationService.unreadCount.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'mark_all_read':
                _markAllAsRead();
                break;
              case 'clear_all':
                _clearAllNotifications();
                break;
              case 'refresh':
                _refreshNotifications();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Mark All Read'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Clear All'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppConstant.primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unread'),
          Tab(text: 'Read'),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Obx(() {
      if (_notificationService.isLoading.value && 
          _notificationService.notifications.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_notificationService.notifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.notifications_none,
          title: 'No Notifications',
          subtitle: 'You don\'t have any notifications yet.',
        );
      }

      return RefreshIndicator(
        onRefresh: () => _notificationService.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notificationService.notifications.length,
          itemBuilder: (context, index) {
            final notification = _notificationService.notifications[index];
            return _buildNotificationCard(notification);
          },
        ),
      );
    });
  }

  Widget _buildUnreadNotificationsTab() {
    return Obx(() {
      final unreadNotifications = _notificationService.notifications
          .where((n) => !n.isRead)
          .toList();

      if (unreadNotifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.mark_email_read,
          title: 'All Caught Up!',
          subtitle: 'You have no unread notifications.',
        );
      }

      return RefreshIndicator(
        onRefresh: () => _notificationService.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: unreadNotifications.length,
          itemBuilder: (context, index) {
            final notification = unreadNotifications[index];
            return _buildNotificationCard(notification);
          },
        ),
      );
    });
  }

  Widget _buildReadNotificationsTab() {
    return Obx(() {
      final readNotifications = _notificationService.notifications
          .where((n) => n.isRead)
          .toList();

      if (readNotifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.history,
          title: 'No Read Notifications',
          subtitle: 'Notifications you\'ve read will appear here.',
        );
      }

      return RefreshIndicator(
        onRefresh: () => _notificationService.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: readNotifications.length,
          itemBuilder: (context, index) {
            final notification = readNotifications[index];
            return _buildNotificationCard(notification);
          },
        ),
      );
    });
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(color: AppConstant.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              color: notification.isRead ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppConstant.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Body
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.isRead ? Colors.grey[600] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Row(
                      children: [
                        // Time
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        // Priority Badge
                        if (notification.priority == 'high')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'High',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[500],
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      if (!notification.isRead) {
                        _notificationService.markAsRead(notification.id);
                      }
                      break;
                    case 'delete':
                      _deleteNotification(notification);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Mark as Read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _refreshNotifications,
      backgroundColor: AppConstant.primaryColor,
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  // Helper Methods
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'schedule_assignment':
        return Icons.schedule;
      case 'schedule_update':
        return Icons.update;
      case 'schedule_cancellation':
        return Icons.cancel;
      case 'attendance_reminder':
        return Icons.alarm;
      case 'check_in':
        return Icons.login;
      case 'check_out':
        return Icons.logout;
      case 'general':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'schedule_assignment':
        return Colors.blue;
      case 'schedule_update':
        return Colors.orange;
      case 'schedule_cancellation':
        return Colors.red;
      case 'attendance_reminder':
        return Colors.purple;
      case 'check_in':
        return Colors.green;
      case 'check_out':
        return Colors.teal;
      case 'general':
        return AppConstant.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Action Methods
  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Handle notification-specific actions
    if (notification.actionType != null) {
      switch (notification.actionType) {
        case 'view_schedule':
          // Navigate to schedule details
          Get.snackbar(
            'Schedule',
            'Opening schedule details...',
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case 'view_attendance':
          // Navigate to attendance details
          Get.snackbar(
            'Attendance',
            'Opening attendance details...',
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case 'open_notifications':
          // Already in notifications screen
          break;
        default:
          // Default action
          break;
      }
    }
  }

  void _markAllAsRead() async {
    final count = await _notificationService.markAllAsRead();
    if (count > 0) {
      Get.snackbar(
        'Success',
        'Marked $count notifications as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _clearAllNotifications() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearAll();
      Get.snackbar(
        'Success',
        'All notifications cleared',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void _refreshNotifications() async {
    await _notificationService.refresh();
    Get.snackbar(
      'Refreshed',
      'Notifications updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _deleteNotification(NotificationModel notification) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _notificationService.deleteNotification(notification.id);
      if (success) {
        Get.snackbar(
          'Success',
          'Notification deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
