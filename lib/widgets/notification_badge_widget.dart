import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/notification_history_service.dart';
import '../utils/app_constant.dart';

/// Reusable notification badge widget for admin screens
class NotificationBadgeWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final double? iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final bool showBadge;
  final String? customBadgeText;

  const NotificationBadgeWidget({
    super.key,
    this.onTap,
    this.iconSize,
    this.iconColor,
    this.badgeColor,
    this.showBadge = true,
    this.customBadgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final notificationService = Get.find<NotificationHistoryService>();
      final unreadCount = notificationService.unreadCount.value;
      
      return Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: iconSize ?? 24,
              color: iconColor ?? AppConstant.textPrimary,
            ),
            onPressed: onTap ?? () => _navigateToNotifications(),
          ),
          if (showBadge && (unreadCount > 0 || customBadgeText != null))
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppConstant.errorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  customBadgeText ?? (unreadCount > 99 ? '99+' : '$unreadCount'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }

  void _navigateToNotifications() {
    Get.toNamed('/notifications');
  }
}

/// Compact notification card widget for dashboard display
class NotificationCardWidget extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String priority;
  final VoidCallback? onTap;

  const NotificationCardWidget({
    super.key,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.priority = 'normal',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: AppConstant.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: isRead ? Colors.grey[700] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Body
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isRead ? Colors.grey[600] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Footer
                    Row(
                      children: [
                        // Time
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        // Priority Badge
                        if (priority == 'high')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'High',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Unread indicator
                        if (!isRead)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppConstant.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      case 'schedule_exchange':
        return Icons.swap_horiz;
      case 'uniform_violation':
        return Icons.warning;
      case 'attendance_approval':
        return Icons.approval;
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
      case 'schedule_exchange':
        return Colors.indigo;
      case 'uniform_violation':
        return Colors.amber;
      case 'attendance_approval':
        return Colors.deepOrange;
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
}

/// Recent notifications widget for dashboard
class RecentNotificationsWidget extends StatelessWidget {
  final int maxItems;
  final VoidCallback? onViewAll;

  const RecentNotificationsWidget({
    super.key,
    this.maxItems = 3,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final notificationService = Get.find<NotificationHistoryService>();
      final notifications = notificationService.notifications.take(maxItems).toList();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppConstant.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstant.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstant.borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...notifications.map((notification) => NotificationCardWidget(
              title: notification.title,
              body: notification.body,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: notification.isRead,
              priority: notification.priority,
              onTap: () => _handleNotificationTap(notification),
            )),
        ],
      );
    });
  }

  void _handleNotificationTap(notification) {
    // Handle notification tap - could navigate to specific screens
    Get.snackbar(
      'Notification',
      'Opening notification details...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
