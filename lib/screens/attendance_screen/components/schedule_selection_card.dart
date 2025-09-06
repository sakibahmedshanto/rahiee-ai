import 'package:flutter/material.dart';
import '../../../utils/app_constant.dart';

class ScheduleSelectionCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onTap;

  const ScheduleSelectionCard({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.parse(schedule['start_date_time']);
    final endTime = DateTime.parse(schedule['end_date_time']);
    final scheduleType = schedule['schedule_type'] ?? 'assigned';
    final canCheckIn = schedule['can_check_in'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: canCheckIn ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canCheckIn ? AppConstant.primaryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              color: canCheckIn ? Colors.white : Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and schedule type
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule['title'] ?? 'Untitled Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: canCheckIn ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScheduleTypeColor(scheduleType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getScheduleTypeLabel(scheduleType),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Time range
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: canCheckIn ? AppConstant.primaryColor : Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: canCheckIn ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Location (if available)
                if (schedule['location'] != null && schedule['location'].toString().isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: canCheckIn ? AppConstant.primaryColor : Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          schedule['location'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: canCheckIn ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                
                // Department (if available)
                if (schedule['department'] != null && schedule['department'].toString().isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: canCheckIn ? AppConstant.primaryColor : Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        schedule['department'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: canCheckIn ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                
                // Description (if available)
                if (schedule['description'] != null && schedule['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    schedule['description'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: canCheckIn ? Colors.grey[700] : Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Action button/status
                Row(
                  children: [
                    Expanded(
                      child: canCheckIn
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppConstant.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login,
                                    size: 16,
                                    color: AppConstant.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tap to Check In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstant.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.block,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Check-in Not Available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScheduleTypeColor(String scheduleType) {
    switch (scheduleType.toLowerCase()) {
      case 'assigned':
        return AppConstant.primaryColor;
      case 'swapped':
        return Colors.orange;
      case 'coverage':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getScheduleTypeLabel(String scheduleType) {
    switch (scheduleType.toLowerCase()) {
      case 'assigned':
        return 'Assigned';
      case 'swapped':
        return 'Swapped';
      case 'coverage':
        return 'Coverage';
      default:
        return 'Schedule';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $amPm';
  }
}
