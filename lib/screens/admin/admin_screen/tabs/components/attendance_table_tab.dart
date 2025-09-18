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
          icon: Icon(Icons.visibility, size: 14),
          padding: EdgeInsets.all(2),
          constraints: BoxConstraints(minWidth: 28, minHeight: 28),
          color: Colors.blue,
        ),
        SizedBox(width: 2),
        IconButton(
          onPressed: () {
            // Edit entry
          },
          icon: Icon(Icons.edit, size: 14),
          padding: EdgeInsets.all(2),
          constraints: BoxConstraints(minWidth: 28, minHeight: 28),
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

  Widget _buildStickyTableHeader() {
    // Calculate total width: 150+100+80+80+100+80+80 = 670
    const double totalWidth = 628; // Reduced from 670 to fix 42px overflow
    
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
              _buildHeaderCell('Employee', 140), // Reduced from 150
              _buildHeaderCell('Department', 90), // Reduced from 100
              _buildHeaderCell('Check In', 75), // Reduced from 80
              _buildHeaderCell('Check Out', 75), // Reduced from 80
              _buildHeaderCell('Working Hours', 90), // Reduced from 100
              _buildHeaderCell('Status', 78), // Reduced from 80
              _buildHeaderCell('Actions', 80), // Same
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
          width: 628, // Same width as header (628px total)
          child: Column(
            children: widget.controller.tableAttendanceList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> employee = entry.value;
              
              return Container(
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildDataCell(_buildEmployeeInfo(employee), 140), // Reduced from 150
                    _buildDataCell(_buildDepartmentChip(employee['department']), 90), // Reduced from 100
                    _buildDataCell(_buildTimeText(employee['checkIn']), 75), // Reduced from 80
                    _buildDataCell(_buildTimeText(employee['checkOut']), 75), // Reduced from 80
                    _buildDataCell(_buildTimeText(employee['workingHours']), 90), // Reduced from 100
                    _buildDataCell(_buildStatusChip(employee['status']), 78), // Reduced from 80
                    _buildDataCell(_buildActionButtons(), 80), // Same
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
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
