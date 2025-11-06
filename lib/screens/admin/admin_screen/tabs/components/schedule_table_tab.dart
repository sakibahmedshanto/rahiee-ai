import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../controllers/admin_controllers/admin_schedule_controller.dart';
import '../../../../../utils/app_constant.dart';
import '../../../../../utils/timezone_utils.dart';

class ScheduleTableTab extends StatefulWidget {
  final AdminController adminController;
  final AdminScheduleController scheduleController;

  const ScheduleTableTab({
    super.key,
    required this.adminController,
    required this.scheduleController,
  });

  @override
  State<ScheduleTableTab> createState() => _ScheduleTableTabState();
}

class _ScheduleTableTabState extends State<ScheduleTableTab> {
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _dataScrollController = ScrollController();

  String _searchQuery = '';
  String _selectedDepartment = 'All Departments';

  List<Map<String, dynamic>> get filteredSchedules {
    var filtered = widget.scheduleController.schedules.toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        final searchLower = _searchQuery.toLowerCase();
        return (schedule['title']?.toString().toLowerCase().contains(searchLower) ?? false) ||
               (schedule['employee_name']?.toString().toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    
    if (_selectedDepartment != 'All Departments') {
      filtered = filtered.where((schedule) => 
        schedule['department']?.toString() == _selectedDepartment).toList();
    }
    
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    widget.scheduleController.loadSchedules();
    
    _headerScrollController.addListener(() {
      if (_dataScrollController.hasClients) {
        _dataScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    
    _dataScrollController.addListener(() {
      if (_headerScrollController.hasClients) {
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
          SliverToBoxAdapter(child: _buildFiltersSection()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minHeight: 60,
              maxHeight: 60,
              child: _buildStickyTableHeader(),
            ),
          ),
          widget.scheduleController.isLoading.value
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstant.primaryColor),
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(child: _buildScrollableTableContent()),
          SliverToBoxAdapter(child: _buildTableFooter()),
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
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Department',
                  _selectedDepartment,
                  ['All Departments', 'IT', 'HR', 'Finance', 'Operations'],
                  (value) => setState(() => _selectedDepartment = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Search schedules...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            fillColor: Colors.white,
            filled: true,
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStickyTableHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstant.primaryColor.withOpacity(0.05),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 3)],
      ),
      child: SingleChildScrollView(
        controller: _headerScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 720,
          child: Row(
            children: [
              _buildHeaderCell('Schedule', 200),
              _buildHeaderCell('Department', 120),
              _buildHeaderCell('Start Time', 120),
              _buildHeaderCell('End Time', 120),
              _buildHeaderCell('Status', 80),
              _buildHeaderCell('Actions', 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildScrollableTableContent() {
    if (filteredSchedules.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text('No schedules found', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        controller: _dataScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 720,
          child: Column(
            children: filteredSchedules.map((schedule) => _buildDataRow(schedule)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> schedule) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildDataCell(Text(schedule['title'] ?? 'Untitled'), 200),
          _buildDataCell(Text(schedule['department'] ?? 'Unknown'), 120),
          _buildDataCell(Text(_formatDateTime(schedule['start_date_time'])), 120),
          _buildDataCell(Text(_formatDateTime(schedule['end_date_time'])), 120),
          _buildDataCell(_buildStatusChip(), 80),
          _buildDataCell(_buildActionButtons(schedule), 80),
        ],
      ),
    );
  }

  Widget _buildDataCell(Widget child, double width) {
    return Container(
      width: width,
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10)),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> schedule) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _viewDetails(schedule),
          icon: Icon(Icons.visibility, size: 16),
          color: AppConstant.primaryColor,
        ),
        IconButton(
          onPressed: () => _editSchedule(schedule),
          icon: Icon(Icons.edit, size: 16),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(
        'Showing ${filteredSchedules.length} schedules',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '--';
    try {
      // Use universal timezone conversion to convert UTC to local time
      final localDateTime = TimezoneUtils.parseToLocal(dateTime);
      if (localDateTime == null) return 'Invalid';
      
      return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year} ${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid';
    }
  }

  void _viewDetails(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Details'),
        content: Text(schedule['title'] ?? 'Untitled'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editSchedule(Map<String, dynamic> schedule) {
    Get.snackbar('Edit', 'Edit functionality coming soon!');
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
