import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_history_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationHistoryService _notificationService = Get.find<NotificationHistoryService>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _notificationService.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          'Notifications${_notificationService.unreadCount.value > 0 ? ' (${_notificationService.unreadCount.value})' : ''}',
        )),
        actions: [
          Obx(() => _notificationService.unreadCount.value > 0
              ? IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    Get.snackbar(
                      'Success',
                      'All notifications marked as read',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                )
              : const SizedBox.shrink()),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'refresh':
                  await _notificationService.refresh();
                  break;
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'filter':
                  _showFilterDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _notificationService.refresh(),
        child: Obx(() {
          if (_notificationService.isLoading.value && 
              _notificationService.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_notificationService.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _notificationService.notifications.length + 
                (_notificationService.isLoading.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _notificationService.notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final notification = _notificationService.notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your notifications here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _notificationService.deleteNotification(notification.id);
        Get.snackbar(
          'Deleted',
          'Notification deleted',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? null : Colors.blue.shade50,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead 
                                    ? FontWeight.normal 
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          _buildNotificationBadge(notification.type),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'schedule_assignment':
        icon = Icons.calendar_today;
        color = Colors.blue;
        break;
      case 'schedule_update':
        icon = Icons.update;
        color = Colors.orange;
        break;
      case 'schedule_cancellation':
        icon = Icons.event_busy;
        color = Colors.red;
        break;
      case 'attendance_reminder':
        icon = Icons.access_time;
        color = Colors.purple;
        break;
      case 'check_in':
      case 'check_out':
        icon = Icons.fingerprint;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildNotificationBadge(String type) {
    String label;
    Color color;

    switch (type) {
      case 'schedule_assignment':
        label = 'Schedule';
        color = Colors.blue;
        break;
      case 'schedule_update':
        label = 'Update';
        color = Colors.orange;
        break;
      case 'schedule_cancellation':
        label = 'Cancelled';
        color = Colors.red;
        break;
      case 'attendance_reminder':
        label = 'Reminder';
        color = Colors.purple;
        break;
      case 'check_in':
        label = 'Check-in';
        color = Colors.green;
        break;
      case 'check_out':
        label = 'Check-out';
        color = Colors.teal;
        break;
      default:
        label = 'General';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if unread
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and action
    if (notification.actionType != null) {
      switch (notification.actionType) {
        case 'view_schedule':
          if (notification.scheduleId != null) {
            // Navigate to schedule details
            Get.toNamed('/schedule/${notification.scheduleId}');
          }
          break;
        case 'view_attendance':
          // Navigate to attendance screen
          Get.toNamed('/attendance');
          break;
        case 'open_app':
          // Just mark as read, already handled
          break;
        default:
          // Show details dialog
          _showNotificationDetails(notification);
      }
    } else {
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildNotificationIcon(notification),
            const SizedBox(width: 12),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              const SizedBox(height: 16),
              if (notification.scheduleData != null) ...[
                const Divider(),
                const Text(
                  'Schedule Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...notification.scheduleData!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(entry.value.toString()),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              Text(
                'Received: ${DateFormat('MMM dd, yyyy at hh:mm a').format(notification.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (notification.actionType == 'view_schedule' && 
              notification.scheduleId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed('/schedule/${notification.scheduleId}');
              },
              child: const Text('View Schedule'),
            ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _notificationService.clearAll();
              Get.snackbar(
                'Cleared',
                'All notifications have been deleted',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inbox),
              title: const Text('All Notifications'),
              onTap: () {
                Navigator.pop(context);
                _notificationService.refresh();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Schedule'),
              onTap: () async {
                Navigator.pop(context);
                final notifications = await _notificationService
                    .getNotificationsByType('schedule_assignment');
                _showFilteredResults(notifications, 'Schedule Notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Attendance'),
              onTap: () async {
                Navigator.pop(context);
                final notifications = await _notificationService
                    .getNotificationsByType('check_in');
                _showFilteredResults(notifications, 'Attendance Notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.markunread),
              title: const Text('Unread Only'),
              onTap: () async {
                Navigator.pop(context);
                final notifications = await _notificationService
                    .fetchUnreadNotifications();
                _showFilteredResults(notifications, 'Unread Notifications');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilteredResults(List<NotificationModel> notifications, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text('No notifications found'))
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


