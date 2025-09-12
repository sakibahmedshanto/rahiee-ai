import 'package:flutter/material.dart';
import '../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../utils/app_constant.dart';

class AttendanceTableTab extends StatefulWidget {
  final AdminController controller;

  const AttendanceTableTab({
    super.key,
    required this.controller,
  });

  @override
  State<AttendanceTableTab> createState() => _AttendanceTableTabState();
}

class _AttendanceTableTabState extends State<AttendanceTableTab> {
  String selectedDepartment = 'All Departments';
  String selectedStatus = 'All Status';
  String selectedDateRange = 'Today';

  final List<Map<String, dynamic>> attendanceData = [
    {
      'name': 'John Smith',
      'avatar': 'JS',
      'department': 'Engineering',
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'workingHours': '8h 30m',
      'status': 'Present',
    },
    {
      'name': 'Sarah Johnson',
      'avatar': 'SJ',
      'department': 'Marketing',
      'checkIn': '08:45 AM',
      'checkOut': '05:45 PM',
      'workingHours': '8h 20m',
      'status': 'Present',
    },
    {
      'name': 'Michael Chen',
      'avatar': 'MC',
      'department': 'Sales',
      'checkIn': '09:15 AM',
      'checkOut': '--',
      'workingHours': 'Active',
      'status': 'Present',
    },
    {
      'name': 'Emily Davis',
      'avatar': 'ED',
      'department': 'HR',
      'checkIn': '--',
      'checkOut': '--',
      'workingHours': '--',
      'status': 'Absent',
    },
    {
      'name': 'David Wilson',
      'avatar': 'DW',
      'department': 'Finance',
      'checkIn': '09:30 AM',
      'checkOut': '06:15 PM',
      'workingHours': '8h 15m',
      'status': 'Late',
    },
    {
      'name': 'Lisa Anderson',
      'avatar': 'LA',
      'department': 'Engineering',
      'checkIn': '--',
      'checkOut': '--',
      'workingHours': '--',
      'status': 'Sick Leave',
    },
    {
      'name': 'Robert Taylor',
      'avatar': 'RT',
      'department': 'Marketing',
      'checkIn': '08:30 AM',
      'checkOut': '05:30 PM',
      'workingHours': '8h 30m',
      'status': 'Present',
    },
    {
      'name': 'Jennifer Brown',
      'avatar': 'JB',
      'department': 'Sales',
      'checkIn': '09:00 AM',
      'checkOut': '--',
      'workingHours': 'Active',
      'status': 'Present',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(),
          
          // Table Section using DataTable
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstant.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, 
                             color: AppConstant.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Employee Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstant.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table Content using ListView
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildDataTable(),
                    ),
                  ),
                  
                  // Footer
                  _buildTableFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // First row of filters
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Department',
                  selectedDepartment,
                  ['All Departments', 'Engineering', 'Marketing', 'Sales', 'HR', 'Finance'],
                  (value) => setState(() => selectedDepartment = value!),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  selectedStatus,
                  ['All Status', 'Present', 'Absent', 'Late', 'Sick Leave'],
                  (value) => setState(() => selectedStatus = value!),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Second row of filters
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Date Range',
                  selectedDateRange,
                  ['Today', 'Yesterday', 'This Week', 'This Month'],
                  (value) => setState(() => selectedDateRange = value!),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Export functionality
                },
                icon: Icon(Icons.download, size: 16),
                label: Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 12),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.grey.shade200,
      ),
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 16,
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
        dataRowHeight: 65,
        headingRowHeight: 50,
        columns: [
          DataColumn(
            label: Text(
              'Employee',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Department',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Check In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Check Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Hours',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
        ],
        rows: attendanceData.map((employee) {
          return DataRow(
            cells: [
              DataCell(_buildEmployeeInfo(employee)),
              DataCell(_buildDepartmentChip(employee['department'])),
              DataCell(_buildTimeText(employee['checkIn'])),
              DataCell(_buildTimeText(employee['checkOut'])),
              DataCell(_buildHoursText(employee['workingHours'])),
              DataCell(_buildStatusChip(employee['status'])),
              DataCell(_buildActionButtons()),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployeeInfo(Map<String, dynamic> employee) {
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
            child: Text(
              employee['avatar'] ?? 'U',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppConstant.primaryColor,
              ),
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  employee['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: EMP${1000 + (employee['name']?.hashCode.abs() ?? 0) % 9999}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstant.textPrimary.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChip(String? department) {
    final dept = department ?? 'Unknown';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDepartmentColor(dept).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        dept,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getDepartmentColor(dept),
        ),
      ),
    );
  }

  Widget _buildTimeText(String? time) {
    final timeStr = time ?? '--';
    return Text(
      timeStr,
      style: TextStyle(
        fontSize: 14,
        color: timeStr == '--' || timeStr == 'Pending' 
            ? Colors.grey 
            : AppConstant.textPrimary,
        fontWeight: timeStr == 'Active' ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildHoursText(String? hours) {
    final hoursStr = hours ?? '--';
    return Text(
      hoursStr,
      style: TextStyle(
        fontSize: 14,
        color: hoursStr == '--' ? Colors.grey : AppConstant.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final statusStr = status ?? 'Unknown';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(statusStr).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusStr,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(statusStr),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            // View details
          },
          icon: Icon(Icons.visibility, size: 16),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          color: Colors.blue,
        ),
        IconButton(
          onPressed: () {
            // Edit entry
          },
          icon: Icon(Icons.edit, size: 16),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Showing ${attendanceData.length} of 150 employees',
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textPrimary.withOpacity(0.7),
            ),
          ),
          Spacer(),
          Text(
            'Page 1 of 19',
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Engineering':
        return Colors.blue;
      case 'Marketing':
        return Colors.purple;
      case 'Sales':
        return Colors.green;
      case 'HR':
        return Colors.orange;
      case 'Finance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      case 'Pending':
        return Colors.blue;
      case 'Sick Leave':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
