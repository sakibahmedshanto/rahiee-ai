// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../../../utils/app_constant.dart';
import '../../../controllers/schedule_controller.dart';
import 'employee_schedule_card.dart';

class RoleSection extends StatelessWidget {
  final String role;
  final List<ScheduleDisplayModel> schedules;

  const RoleSection({
    super.key,
    required this.role,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getRoleColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Employee cards
          ...schedules.map((schedule) => EmployeeScheduleCard(
            scheduleDisplay: schedule,
          )).toList(),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (role.toLowerCase()) {
      case 'bartender':
        return AppConstant.primaryColor;
      case 'busser':
        return const Color(0xFF8B4513); // Brown color for busser
      case 'server':
        return const Color(0xFF228B22); // Green for server
      case 'manager':
        return const Color(0xFF800080); // Purple for manager
      default:
        return AppConstant.secondaryColor;
    }
  }
}
