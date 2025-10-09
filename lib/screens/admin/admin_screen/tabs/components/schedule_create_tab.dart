import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../controllers/admin_controllers/admin_schedule_controller.dart';
import '../../../../../utils/app_constant.dart';

class ScheduleCreateTab extends StatefulWidget {
  final AdminController adminController;
  final AdminScheduleController scheduleController;

  const ScheduleCreateTab({
    super.key,
    required this.adminController,
    required this.scheduleController,
  });

  @override
  State<ScheduleCreateTab> createState() => _ScheduleCreateTabState();
}

class _ScheduleCreateTabState extends State<ScheduleCreateTab> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _requirementsController = TextEditingController();
  
  // Form State Variables
  String? _selectedUserId;
  List<String> _selectedUserIds = []; // For multi-user assignment
  bool _isMultiUserMode = false; // Toggle for multi-user
  String? _selectedDepartment;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  double? _latitude;
  double? _longitude;
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  int? _maxParticipants; // Max users for multi-user schedules
  int _minParticipants = 1; // Min users required

  // Dropdown Options
  final List<String> _departments = [
    'IT',
    'HR', 
    'Finance',
    'Operations',
    'Marketing',
    'Sales',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    // Load available users when the tab is initialized
    _loadAvailableUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _requirementsController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _loadAvailableUsers() {
    widget.scheduleController.loadAvailableUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              SizedBox(height: 24),
              
              // Basic Information Section
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Schedule Title',
                    hint: 'e.g., Morning Shift - IT Department',
                    required: true,
                    icon: Icons.title,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Brief description of the schedule...',
                    maxLines: 3,
                    icon: Icons.description,
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Assignment Section
              _buildSectionCard(
                title: 'Employee Assignment',
                icon: Icons.person_outline,
                children: [
                  // Multi-user toggle
                  _buildMultiUserToggle(),
                  SizedBox(height: 16),
                  
                  // User selection (single or multi)
                  _isMultiUserMode 
                    ? _buildMultiUserSelection()
                    : _buildUserDropdown(),
                  
                  // Participant limits for multi-user
                  if (_isMultiUserMode) ...[
                    SizedBox(height: 16),
                    _buildParticipantLimits(),
                  ],
                  
                  SizedBox(height: 16),
                  _buildDepartmentDropdown(),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Date & Time Section
              _buildSectionCard(
                title: 'Date & Time',
                icon: Icons.schedule,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDateTimePicker(true)),
                      SizedBox(width: 16),
                      Expanded(child: _buildDateTimePicker(false)),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Location Section
              _buildSectionCard(
                title: 'Location Details',
                icon: Icons.location_on_outlined,
                children: [
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'e.g., Main Office, Building A, Remote',
                    required: true,
                    icon: Icons.place,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: TextEditingController(
                            text: _latitude?.toString() ?? '',
                          ),
                          label: 'Latitude (Optional)',
                          hint: '0.0',
                          keyboardType: TextInputType.number,
                          icon: Icons.my_location,
                          onChanged: (value) {
                            _latitude = double.tryParse(value);
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: TextEditingController(
                            text: _longitude?.toString() ?? '',
                          ),
                          label: 'Longitude (Optional)',
                          hint: '0.0',
                          keyboardType: TextInputType.number,
                          icon: Icons.my_location,
                          onChanged: (value) {
                            _longitude = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Additional Details Section
              _buildSectionCard(
                title: 'Additional Details',
                icon: Icons.more_horiz,
                children: [
                  _buildTextField(
                    controller: _requirementsController,
                    label: 'Requirements (JSON format)',
                    hint: '{"security_clearance": true, "training": "basic"}',
                    maxLines: 3,
                    icon: Icons.rule,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Additional notes for this schedule...',
                    maxLines: 3,
                    icon: Icons.note,
                  ),
                  SizedBox(height: 16),
                  _buildTagsSection(),
                ],
              ),
              
              SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(),
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstant.primaryColor,
            AppConstant.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstant.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_task,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Assign work schedules to employees',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppConstant.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    IconData? icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstant.primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildMultiUserToggle() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstant.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            _isMultiUserMode ? Icons.people : Icons.person,
            color: AppConstant.primaryColor,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allow Multiple Users',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enable multi-user assignment for this schedule',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isMultiUserMode,
            onChanged: (value) {
              setState(() {
                _isMultiUserMode = value;
                if (!value) {
                  _selectedUserIds.clear();
                  _maxParticipants = null;
                  _minParticipants = 1;
                }
              });
            },
            activeColor: AppConstant.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiUserSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assign Employees *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstant.textPrimary,
              ),
            ),
            Text(
              '${_selectedUserIds.length} selected',
              style: TextStyle(
                fontSize: 12,
                color: AppConstant.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showMultiUserSelectionDialog,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppConstant.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedUserIds.isEmpty
                            ? 'Tap to select employees'
                            : '${_selectedUserIds.length} employee(s) selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedUserIds.isEmpty
                              ? AppConstant.textSecondary
                              : AppConstant.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppConstant.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Show selected users
        if (_selectedUserIds.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedUserIds.map((userId) {
              final user = widget.scheduleController.availableUsers
                  .firstWhere((u) => u['id'] == userId, orElse: () => {});
              final userName = user['full_name'] ?? 'Unknown';
              
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppConstant.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(userName),
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedUserIds.remove(userId);
                  });
                },
                backgroundColor: Colors.white,
                shape: StadiumBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildParticipantLimits() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min Participants',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstant.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                initialValue: _minParticipants.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.people_outline, size: 20),
                  hintText: 'Min users',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstant.primaryColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _minParticipants = int.tryParse(value) ?? 1;
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Max Participants',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstant.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                initialValue: _maxParticipants?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.people, size: 20),
                  hintText: 'Max users (optional)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstant.primaryColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _maxParticipants = value.isEmpty ? null : int.tryParse(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Employee *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedUserId,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text('Select an employee'),
            items: widget.scheduleController.availableUsers
                .map<DropdownMenuItem<String>>((user) {
              return DropdownMenuItem<String>(
                value: user['id'],
                child: Text(
                  user['full_name'] ?? 'Unknown',
                  style: TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUserId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an employee';
              }
              return null;
            },
          ),
        )),
        SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _loadAvailableUsers,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Refresh Users'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstant.primaryColor,
              ),
            ),
            Spacer(),
            if (_startDateTime != null && _endDateTime != null)
              TextButton.icon(
                onPressed: () {
                  widget.scheduleController.loadAvailableUsers(
                    startDateTime: _startDateTime,
                    endDateTime: _endDateTime,
                  );
                },
                icon: Icon(Icons.filter_list, size: 16),
                label: Text('Filter Available'),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstant.primaryColor,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDepartment,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.business, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text('Select department'),
            items: _departments.map<DropdownMenuItem<String>>((dept) {
              return DropdownMenuItem<String>(
                value: dept,
                child: Text(dept),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDepartment = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a department';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(bool isStart) {
    final label = isStart ? 'Start Date & Time' : 'End Date & Time';
    final currentValue = isStart ? _startDateTime : _endDateTime;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(isStart),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(isStart ? Icons.schedule : Icons.schedule_outlined, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentValue != null
                        ? '${currentValue.day}/${currentValue.month}/${currentValue.year} ${currentValue.hour}:${currentValue.minute.toString().padLeft(2, '0')}'
                        : 'Select $label',
                    style: TextStyle(
                      fontSize: 14,
                      color: currentValue != null ? AppConstant.textPrimary : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  prefixIcon: Icon(Icons.tag, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstant.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstant.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Add'),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => _buildTag(tag)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstant.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: AppConstant.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close,
              size: 16,
              color: AppConstant.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstant.textPrimary,
              side: BorderSide(color: Colors.grey.shade300),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Reset Form'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Obx(() => ElevatedButton(
            onPressed: widget.scheduleController.isCreatingSchedule.value
                ? null
                : _createSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.scheduleController.isCreatingSchedule.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Creating...'),
                    ],
                  )
                : Text('Create Schedule'),
          )),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStart) {
            _startDateTime = dateTime;
            // If start time is after end time, reset end time
            if (_endDateTime != null && dateTime.isAfter(_endDateTime!)) {
              _endDateTime = null;
            }
          } else {
            if (_startDateTime != null && dateTime.isBefore(_startDateTime!)) {
              Get.snackbar(
                'Invalid Time',
                'End time must be after start time',
                backgroundColor: Colors.red.withOpacity(0.8),
                colorText: Colors.white,
              );
            } else {
              _endDateTime = dateTime;
            }
          }
        });

        // Refresh available users if both times are set
        if (_startDateTime != null && _endDateTime != null) {
          widget.scheduleController.loadAvailableUsers(
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
          );
        }
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showMultiUserSelectionDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: AppConstant.primaryColor),
            SizedBox(width: 8),
            Text('Select Employees'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Obx(() {
            if (widget.scheduleController.availableUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No employees available',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    TextButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh'),
                      onPressed: () => widget.scheduleController.loadAvailableUsers(),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              itemCount: widget.scheduleController.availableUsers.length,
              itemBuilder: (context, index) {
                final user = widget.scheduleController.availableUsers[index];
                final userId = user['id'] as String;
                final isSelected = _selectedUserIds.contains(userId);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedUserIds.add(userId);
                      } else {
                        _selectedUserIds.remove(userId);
                      }
                    });
                  },
                  title: Text(
                    user['full_name'] ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['email'] != null)
                        Text(user['email'], style: TextStyle(fontSize: 12)),
                      if (user['department'] != null)
                        Text(
                          '${user['department']} - ${user['position'] ?? 'Employee'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: isSelected
                        ? AppConstant.primaryColor
                        : Colors.grey.shade300,
                    child: Text(
                      (user['full_name'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  activeColor: AppConstant.primaryColor,
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.check, color: Colors.white),
            label: Text(
              'Done (${_selectedUserIds.length})',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              setState(() {}); // Update UI
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _notesController.clear();
      _requirementsController.clear();
      _tagController.clear();
      _selectedUserId = null;
      _selectedUserIds.clear();
      _isMultiUserMode = false;
      _maxParticipants = null;
      _minParticipants = 1;
      _selectedDepartment = null;
      _startDateTime = null;
      _endDateTime = null;
      _latitude = null;
      _longitude = null;
      _tags.clear();
    });
  }

  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDateTime == null || _endDateTime == null) {
      Get.snackbar(
        'Missing Information',
        'Please select both start and end date/time',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Validate user assignment
    if (_isMultiUserMode) {
      if (_selectedUserIds.isEmpty) {
        Get.snackbar(
          'Missing Information',
          'Please select at least one employee to assign',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      // Validate minimum participants
      if (_selectedUserIds.length < _minParticipants) {
        Get.snackbar(
          'Invalid Selection',
          'Please select at least $_minParticipants employee(s)',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      // Validate maximum participants
      if (_maxParticipants != null && _selectedUserIds.length > _maxParticipants!) {
        Get.snackbar(
          'Invalid Selection',
          'Maximum $_maxParticipants employee(s) allowed',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
    } else {
      if (_selectedUserId == null) {
        Get.snackbar(
          'Missing Information',
          'Please select an employee to assign',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
    }

    // Parse requirements JSON if provided
    Map<String, dynamic>? requirements;
    if (_requirementsController.text.trim().isNotEmpty) {
      try {
        requirements = {
          'requirements': _requirementsController.text.trim(),
        };
      } catch (e) {
        Get.snackbar(
          'Invalid Requirements',
          'Requirements must be in valid JSON format',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
    }

    // Create schedule (without assignment)
    final scheduleResult = await widget.scheduleController.createSchedule(
      title: _titleController.text.trim(),
      startDateTime: _startDateTime!,
      endDateTime: _endDateTime!,
      department: _selectedDepartment!,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      latitude: _latitude,
      longitude: _longitude,
      requirements: requirements,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      tags: _tags.isNotEmpty ? _tags : null,
      isMultiUser: _isMultiUserMode,
      maxParticipants: _maxParticipants,
      minParticipants: _minParticipants,
    );

    // If schedule created successfully, assign users
    if (scheduleResult['success'] == true) {
      final scheduleId = scheduleResult['schedule_id']?.toString();
      
      if (scheduleId != null && scheduleId.isNotEmpty) {
        // Get user IDs to assign
        final userIdsToAssign = _isMultiUserMode ? _selectedUserIds : [_selectedUserId!];
        
        // Assign users to the schedule
        final assignResult = await widget.scheduleController.assignMultipleUsersToSchedule(
          scheduleId: scheduleId,
          userIds: userIdsToAssign,
          notes: _isMultiUserMode 
            ? 'Multi-user schedule created with ${userIdsToAssign.length} employees'
            : 'Schedule created and assigned to employee',
        );
        
        if (assignResult) {
          Get.snackbar(
            'Success',
            _isMultiUserMode
              ? 'Schedule created and ${userIdsToAssign.length} employee(s) assigned'
              : 'Schedule created and employee assigned successfully',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'Partial Success',
            'Schedule created, but failed to assign users. Please assign them manually.',
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 4),
          );
        }
      } else {
        Get.snackbar(
          'Partial Success',
          'Schedule created, but could not retrieve schedule ID for assignment. Please assign users manually from the schedule list.',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }
    }

    // Reset form on success
    if (scheduleResult['success'] == true) {
      _resetForm();
    }
  }
}