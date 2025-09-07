// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../../../../utils/app_constant.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildActionCard(
          title: 'Review Attendance',
          icon: Icons.fact_check_outlined,
          color: AppConstant.warningColor,
          onTap: () {
            // Navigate to attendance review
            // Switch to attendance tab - will be implemented when navigation is needed
          },
        ),
        _buildActionCard(
          title: 'Create Schedule',
          icon: Icons.add_circle_outline,
          color: AppConstant.primaryColor,
          onTap: () {
            // Navigate to schedule creation
          },
        ),
        _buildActionCard(
          title: 'Employee Reports',
          icon: Icons.analytics_outlined,
          color: AppConstant.accentColor,
          onTap: () {
            // Navigate to reports
          },
        ),
        _buildActionCard(
          title: 'Payroll Review',
          icon: Icons.attach_money,
          color: AppConstant.successColor,
          onTap: () {
            // Navigate to payroll
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstant.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstant.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppConstant.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstant.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
