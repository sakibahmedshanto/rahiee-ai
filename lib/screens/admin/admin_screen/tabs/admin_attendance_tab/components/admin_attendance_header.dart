import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../../utils/app_constant.dart';

class AdminAttendanceHeader extends StatelessWidget {
  final AdminController controller;
  
  const AdminAttendanceHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Refresh button
          _buildActionButton(
            icon: Icons.refresh,
            tooltip: 'Refresh Data',
            onPressed: () => controller.refreshAttendanceData(),
          ),
          const SizedBox(width: 8),
          
          // Date filter button
          _buildActionButton(
            icon: Icons.date_range,
            tooltip: 'Date Filter',
            onPressed: () => _showDateFilterDialog(context),
          ),
          const SizedBox(width: 8),
          
          // Status filter dropdown
          _buildFilterDropdown(
            icon: Icons.filter_list,
            tooltip: 'Filter by Status',
            items: [
              {'value': 'pending', 'label': 'Pending Only'},
              {'value': 'all', 'label': 'All Records'},
            ],
            currentValue: controller.selectedAttendanceFilter.value,
            onChanged: (value) async {
              controller.selectedAttendanceFilter.value = value;
              switch (value) {
                case 'pending':
                  await controller.loadPendingAttendance();
                  break;
                case 'all':
                  await controller.loadAllAttendance();
                  break;
              }
            },
          ),
          const SizedBox(width: 8),
          
          // Department filter dropdown
          _buildFilterDropdown(
            icon: Icons.business,
            tooltip: 'Filter by Department',
            items: controller.departments.map((dept) => {
              'value': dept,
              'label': dept,
            }).toList(),
            currentValue: controller.selectedDepartment.value,
            onChanged: (value) async {
              controller.selectedDepartment.value = value;
              controller.refreshAttendanceData();
            },
          ),
          
          const Spacer(),
          
          // Export button
          _buildActionButton(
            icon: Icons.download,
            tooltip: 'Export Data',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstant.primaryColor.withOpacity(0.2)),
            ),
            child: Icon(
              icon,
              color: AppConstant.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String tooltip,
    required List<Map<String, String>> items,
    required String currentValue,
    required Function(String) onChanged,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstant.primaryColor.withOpacity(0.2)),
        ),
        child: PopupMenuButton<String>(
          icon: Icon(icon, color: AppConstant.primaryColor, size: 20),
          onSelected: onChanged,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context) => items.map((item) => 
            PopupMenuItem(
              value: item['value'],
              child: Text(item['label']!),
            ),
          ).toList(),
        ),
      ),
    );
  }

  void _showDateFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateFilterOption('today', 'Today', context),
            _buildDateFilterOption('week', 'This Week', context),
            _buildDateFilterOption('month', 'This Month', context),
            _buildDateFilterOption('all', 'All Time', context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterOption(String value, String label, BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: Radio(
        value: value,
        groupValue: controller.dateFilterType.value,
        onChanged: (selectedValue) {
          if (selectedValue == 'today') {
            controller.setDateFilterToday();
          } else if (selectedValue == 'all') {
            controller.setDateFilterAll();
          } else {
            controller.dateFilterType.value = selectedValue!;
            controller.refreshAttendanceData();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Attendance Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement CSV export
              Navigator.pop(context);
              Get.snackbar('Info', 'CSV export coming soon');
            },
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}
