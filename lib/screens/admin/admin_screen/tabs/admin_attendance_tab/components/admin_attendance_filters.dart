import 'package:flutter/material.dart';
import '../../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../../utils/app_constant.dart';

class AdminAttendanceFilters extends StatelessWidget {
  final AdminController controller;
  
  const AdminAttendanceFilters({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Today',
              'today',
              Icons.today,
              controller.dateFilterType.value == 'today',
              () => controller.setDateFilterToday(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'This Week',
              'week',
              Icons.date_range,
              controller.dateFilterType.value == 'week',
              () {
                controller.dateFilterType.value = 'week';
                controller.refreshAttendanceData();
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'This Month',
              'month',
              Icons.calendar_month,
              controller.dateFilterType.value == 'month',
              () {
                controller.dateFilterType.value = 'month';
                controller.refreshAttendanceData();
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'All Time',
              'all',
              Icons.all_inclusive,
              controller.dateFilterType.value == 'all',
              () => controller.setDateFilterAll(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Custom Range',
              'range',
              Icons.event_available,
              controller.dateFilterType.value == 'range',
              () => _showCustomDatePicker(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppConstant.primaryColor 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? AppConstant.primaryColor 
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDatePicker(BuildContext context) async {
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select start date',
    );

    if (startDate != null) {
      final DateTime? endDate = await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: startDate,
        lastDate: DateTime.now(),
        helpText: 'Select end date',
      );

      if (endDate != null) {
        controller.dateFilterType.value = 'range';
        // TODO: Implement custom date range filtering
        controller.refreshAttendanceData();
      }
    }
  }
}
