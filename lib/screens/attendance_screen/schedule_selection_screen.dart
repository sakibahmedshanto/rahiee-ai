import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/attendance_management_service.dart';
import '../../utils/app_constant.dart';
import 'components/schedule_selection_card.dart';
import 'schedule_check_in_screen.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  const ScheduleSelectionScreen({super.key});

  @override
  State<ScheduleSelectionScreen> createState() => _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final RxList<Map<String, dynamic>> availableSchedules = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedDate = DateTime.now().toIso8601String().split('T')[0].obs;

  @override
  void initState() {
    super.initState();
    _loadAvailableSchedules();
  }

  Future<void> _loadAvailableSchedules() async {
    try {
      isLoading.value = true;
      final schedules = await _attendanceService.getAvailableSchedulesForEmployee(
        date: DateTime.parse(selectedDate.value),
      );
      availableSchedules.assignAll(schedules);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load schedules: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(selectedDate.value),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstant.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate.value = picked.toIso8601String().split('T')[0];
      _loadAvailableSchedules();
    }
  }

  void _onScheduleSelected(Map<String, dynamic> schedule) {
    // Navigate to check-in screen with selected schedule
    Get.to(() => ScheduleCheckInScreen(schedule: schedule));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Select Schedule to Check In',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstant.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date',
          ),
          IconButton(
            onPressed: _loadAvailableSchedules,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Obx(() => Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppConstant.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected Date: ${_formatDate(selectedDate.value)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: Icon(
                    Icons.edit_calendar,
                    color: AppConstant.primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    'Change',
                    style: TextStyle(color: AppConstant.primaryColor),
                  ),
                ),
              ],
            )),
          ),
          
          // Schedules list
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (availableSchedules.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No schedules available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have no schedules assigned for this date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Select Different Date'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstant.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadAvailableSchedules,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = availableSchedules[index];
                    return ScheduleSelectionCard(
                      schedule: schedule,
                      onTap: () => _onScheduleSelected(schedule),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
