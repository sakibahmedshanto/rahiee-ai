import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  // Scroll controllers for synchronized scrolling
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _dataScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Load data when the tab is initialized
    widget.controller.loadAttendanceTableData();
    
    // Synchronize horizontal scrolling between header and data
    _headerScrollController.addListener(() {
      if (_dataScrollController.hasClients && !_dataScrollController.position.isScrollingNotifier.value) {
        _dataScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    
    _dataScrollController.addListener(() {
      if (_headerScrollController.hasClients && !_headerScrollController.position.isScrollingNotifier.value) {
        _headerScrollController.jumpTo(_dataScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _dataScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Filters Section
          SliverToBoxAdapter(
            child: _buildFiltersSection(),
          ),
          
          // Sticky Table Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minHeight: 60,
              maxHeight: 60,
              child: _buildStickyTableHeader(),
            ),
          ),
          
          // Table Content with loading state
          widget.controller.isTableLoading.value
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: _buildScrollableTableContent(),
                ),
          
          // Footer
          SliverToBoxAdapter(
            child: _buildTableFooter(),
          ),
        ],
      ),
    ));
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
                  widget.controller.tableSelectedDepartment.value,
                  ['All Departments', 'Engineering', 'Marketing', 'Sales', 'HR', 'Finance'],
                  (value) {
                    widget.controller.tableSelectedDepartment.value = value!;
                    widget.controller.loadAttendanceTableData();
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  widget.controller.tableSelectedStatus.value,
                  ['All Status', 'Present', 'Absent', 'Late', 'Sick Leave'],
                  (value) {
                    widget.controller.tableSelectedStatus.value = value!;
                    widget.controller.loadAttendanceTableData();
                  },
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
                  widget.controller.tableSelectedDateRange.value,
                  ['Today', 'Yesterday', 'This Week', 'This Month'],
                  (value) {
                    widget.controller.tableSelectedDateRange.value = value!;
                    widget.controller.loadAttendanceTableData();
                  },
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

  Widget _buildEmployeeInfo(Map<String, dynamic> employee) {
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
            child: Text(
              employee['avatar'] ?? 'U',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppConstant.primaryColor,
              ),
            ),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  employee['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: EMP${1000 + (employee['name']?.hashCode.abs() ?? 0) % 9999}',
                  style: TextStyle(
                    fontSize: 9,
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

  Widget _buildActionButtons(Map<String, dynamic> employee) {
    String currentStatus = employee['status'] ?? 'pending';
    
    return Container(
      width: 140, // Increased width to better fit the column
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _getStatusButtonColor(currentStatus),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        value: currentStatus,
        isDense: true,
        underline: Container(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        isExpanded: true,
        dropdownColor: Colors.white,
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
        items: [
          'pending',
          'granted', 
          'not_granted',
          'completed',
          'approved',
          'rejected'
        ].map((status) => DropdownMenuItem(
          value: status,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusIndicatorColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
        selectedItemBuilder: (context) => [
          'pending',
          'granted', 
          'not_granted',
          'completed',
          'approved',
          'rejected'
        ].map((status) => Container(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getStatusIndicatorColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4),
              Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )).toList(),
        onChanged: (newStatus) {
          if (newStatus != null && newStatus != currentStatus) {
            _showStatusChangeDialog(employee, newStatus);
          }
        },
      ),
    );
  }

  // Helper method to get status button background color (lighter version)
  Color _getStatusButtonColor(String status) {
    switch (status.toLowerCase()) {
      case 'granted':
      case 'approved':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'not_granted':
      case 'rejected':
        return Colors.red.shade50;
      case 'completed':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  // Helper method to get status indicator color (solid color for the dot)
  Color _getStatusIndicatorColor(String status) {
    switch (status.toLowerCase()) {
      case 'granted':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'not_granted':
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Show confirmation dialog for status change
  void _showStatusChangeDialog(Map<String, dynamic> employee, String newStatus) {
    String adminNotes = '';
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${employee['name'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            Text('Current Status: ${employee['status'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            Text('New Status: $newStatus'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                adminNotes = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get attendance ID from employee data with null safety
              final attendanceId = employee['attendance_id'];
              
              if (attendanceId == null || attendanceId.toString().isEmpty) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Missing attendance ID')),
                  );
                }
                return;
              }
              
              // Store scaffold messenger reference before closing dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Close dialog first
              Navigator.pop(dialogContext);
              
              try {
                // Update status
                final success = await widget.controller.updateAttendanceStatus(
                  attendanceId: attendanceId.toString(),
                  newStatus: newStatus,
                  adminNotes: adminNotes.isNotEmpty ? adminNotes : 'Status changed by admin',
                  reviewReason: 'Admin review',
                  calculatedAmount: 0.0, // Provide default value
                  adjustedHours: 0.0, // Provide default value
                );
                
                // Check if widget is still mounted before showing messages
                if (mounted) {
                  if (success) {
                    // Refresh the attendance data
                    await widget.controller.loadAttendanceTableData();
                    
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Status updated successfully')),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to update status')),
                    );
                  }
                }
              } catch (e) {
                // Handle any errors that might occur
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
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
            'Showing ${widget.controller.tableAttendanceList.length} of ${widget.controller.tableTotalRecords.value} employees',
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

  Widget _buildStickyTableHeader() {
    // Calculate total width: 140+90+75+75+90+150 = 620
    const double totalWidth = 620; // Match the data table width
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstant.primaryColor.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _headerScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Row(
            children: [
              _buildHeaderCell('Employee', 140), // Same
              _buildHeaderCell('Department', 90), // Same
              _buildHeaderCell('Check In', 75), // Same
              _buildHeaderCell('Check Out', 75), // Same
              _buildHeaderCell('Working Hours', 90), // Same
              _buildHeaderCell('Status / Actions', 150), // Combined Status and Actions
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return SizedBox(
      width: width,
      height: 50,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppConstant.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableTableContent() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _dataScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 620, // Updated to match header width (620px total)
          child: Column(
            children: widget.controller.tableAttendanceList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> employee = entry.value;
              
              return Container(
                decoration: BoxDecoration(
                  color: _getStatusRowColor(employee['status'] ?? '', index),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildDataCell(_buildEmployeeInfo(employee), 140), // Same
                    _buildDataCell(_buildDepartmentChip(employee['department']), 90), // Same
                    _buildDataCell(_buildTimeText(employee['checkIn']), 75), // Same
                    _buildDataCell(_buildTimeText(employee['checkOut']), 75), // Same
                    _buildDataCell(_buildTimeText(employee['workingHours']), 90), // Same
                    _buildDataCell(_buildActionButtons(employee), 150), // Combined Status and Actions
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Helper method to get status-based row color
  Color _getStatusRowColor(String status, int index) {
    switch (status.toLowerCase()) {
      case 'granted':
      case 'approved':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'not_granted':
      case 'rejected':
        return Colors.red.shade50;
      case 'completed':
        return Colors.blue.shade50;
      default:
        return index % 2 == 0 ? Colors.grey.shade50 : Colors.white;
    }
  }

  Widget _buildDataCell(Widget child, double width) {
    return SizedBox(
      width: width,
      height: 60,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
           minHeight != oldDelegate.minHeight ||
           child != oldDelegate.child;
  }
}
