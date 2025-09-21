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
  String? _selectedDepartment;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  double? _latitude;
  double? _longitude;
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

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
                  _buildUserDropdown(),
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

    if (_selectedUserId == null) {
      Get.snackbar(
        'Missing Information',
        'Please select an employee to assign',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
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

    await widget.scheduleController.createSchedule(
      title: _titleController.text.trim(),
      startDateTime: _startDateTime!,
      endDateTime: _endDateTime!,
      assignedUserId: _selectedUserId!,
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
    );

    // Reset form on success
    if (widget.scheduleController.schedules.isNotEmpty) {
      _resetForm();
    }
  }
}