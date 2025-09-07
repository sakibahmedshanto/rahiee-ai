// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../../../../utils/app_constant.dart';

class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;

  const CustomDateRangePickerDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  });

  @override
  State<CustomDateRangePickerDialog> createState() => _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState extends State<CustomDateRangePickerDialog> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    startDate = widget.initialStartDate ?? DateTime.now().subtract(Duration(days: 30));
    endDate = widget.initialEndDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select Date Range',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstant.textPrimary,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Date Selector
            _buildDateSelector(
              label: 'Start Date',
              date: startDate!,
              onTap: () => _selectStartDate(context),
            ),
            SizedBox(height: 16),
            // End Date Selector
            _buildDateSelector(
              label: 'End Date',
              date: endDate!,
              onTap: () => _selectEndDate(context),
            ),
            SizedBox(height: 16),
            // Quick Select Options
            _buildQuickSelectOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppConstant.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isValidDateRange() ? () {
            widget.onDateRangeSelected(startDate!, endDate!);
            Navigator.pop(context);
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstant.primaryColor,
          ),
          child: Text(
            'Apply',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppConstant.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppConstant.primaryColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.textPrimary,
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: AppConstant.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickSelectChip('Last 7 days', () => _setDateRange(7)),
            _buildQuickSelectChip('Last 30 days', () => _setDateRange(30)),
            _buildQuickSelectChip('Last 3 months', () => _setDateRange(90)),
            _buildQuickSelectChip('This month', () => _setThisMonth()),
            _buildQuickSelectChip('Last month', () => _setLastMonth()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppConstant.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstant.primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppConstant.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate!,
      firstDate: DateTime(2020),
      lastDate: endDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstant.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        if (endDate!.isBefore(startDate!)) {
          endDate = startDate;
        }
      });
    }
  }

  void _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate!,
      firstDate: startDate!,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstant.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }

  void _setDateRange(int days) {
    setState(() {
      endDate = DateTime.now();
      startDate = endDate!.subtract(Duration(days: days));
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0);
    });
  }

  bool _isValidDateRange() {
    return startDate != null && 
           endDate != null && 
           !endDate!.isBefore(startDate!);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
