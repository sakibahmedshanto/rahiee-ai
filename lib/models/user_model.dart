// ignore_for_file: file_names

class UserModel {
  final String uId;
  final String employeeId;
  final String username;
  final String email;
  final String phone;
  final String? userImg; // Optional profile image
  final String? userDeviceToken; // Optional for push notifications
  final String fullName;
  final String department;
  final String position;
  final String userRole; // 'employee', 'admin', 'ceo', 'manager'
  final bool isActive;
  final DateTime? createdOn;
  
  // Attendance-specific fields
  final String? workLocation; // Optional work location/office
  final String? shiftType; // Optional: 'morning', 'evening', 'night', 'flexible'
  final String? supervisorId; // Optional supervisor employee ID
  final double? salaryRate; // Optional for payroll integration
  final String? emergencyContact; // Optional emergency contact
  final String? emergencyPhone; // Optional emergency phone
  
  // App-specific settings
  final bool? biometricEnabled; // Optional biometric login setting
  final String? preferredLanguage; // Optional language preference
  final bool? notificationsEnabled; // Optional notification setting
  
  // Analytics and tracking (optional)
  final int? totalCoverageGiven; // How many times helped others
  final int? totalCoverageReceived; // How many times received help
  final double? attendanceRate; // Attendance percentage
  final int? leaveBalance; // Remaining leave days

  UserModel({
    required this.uId,
    required this.employeeId,
    required this.username,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.department,
    required this.position,
    required this.userRole,
    required this.isActive,
    this.createdOn,
    this.userImg,
    this.userDeviceToken,
    this.workLocation,
    this.shiftType,
    this.supervisorId,
    this.salaryRate,
    this.emergencyContact,
    this.emergencyPhone,
    this.biometricEnabled,
    this.preferredLanguage,
    this.notificationsEnabled,
    this.totalCoverageGiven,
    this.totalCoverageReceived,
    this.attendanceRate,
    this.leaveBalance,
  });

  // Serialize the UserModel instance to a JSON map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': uId, // Supabase uses 'id' as primary key
      'employee_id': employeeId,
      'username': username,
      'email': email,
      'phone': phone,
      'user_img': userImg,
      'user_device_token': userDeviceToken,
      'full_name': fullName,
      'department': department,
      'position': position,
      'user_role': userRole,
      'is_active': isActive,
      'created_on': createdOn?.toIso8601String(),
      'work_location': workLocation,
      'shift_type': shiftType,
      'supervisor_id': supervisorId,
      'salary_rate': salaryRate,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'biometric_enabled': biometricEnabled,
      'preferred_language': preferredLanguage,
      'notifications_enabled': notificationsEnabled,
      'total_coverage_given': totalCoverageGiven,
      'total_coverage_received': totalCoverageReceived,
      'attendance_rate': attendanceRate,
      'leave_balance': leaveBalance,
    };
  }

  // Create a UserModel instance from a Supabase JSON map
  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      uId: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      userRole: json['user_role']?.toString() ?? 'employee',
      isActive: json['is_active'] as bool? ?? true,
      createdOn: json['created_on'] != null ? DateTime.parse(json['created_on']) : null,
      userImg: json['user_img']?.toString(),
      userDeviceToken: json['user_device_token']?.toString(),
      workLocation: json['work_location']?.toString(),
      shiftType: json['shift_type']?.toString(),
      supervisorId: json['supervisor_id']?.toString(),
      salaryRate: json['salary_rate']?.toDouble(),
      emergencyContact: json['emergency_contact']?.toString(),
      emergencyPhone: json['emergency_phone']?.toString(),
      biometricEnabled: json['biometric_enabled'] as bool?,
      preferredLanguage: json['preferred_language']?.toString(),
      notificationsEnabled: json['notifications_enabled'] as bool?,
      totalCoverageGiven: json['total_coverage_given'] as int?,
      totalCoverageReceived: json['total_coverage_received'] as int?,
      attendanceRate: json['attendance_rate']?.toDouble(),
      leaveBalance: json['leave_balance'] as int?,
    );
  }

  // Helper methods for common checks
  bool get isAdmin => userRole == 'admin' || userRole == 'ceo';
  bool get isCEO => userRole == 'ceo';
  bool get isManager => userRole == 'manager';
  bool get isEmployee => userRole == 'employee';
  
  // Helper method to create a copy with updated fields
  UserModel copyWith({
    String? uId,
    String? employeeId,
    String? username,
    String? email,
    String? phone,
    String? userImg,
    String? userDeviceToken,
    String? fullName,
    String? department,
    String? position,
    String? userRole,
    bool? isActive,
    DateTime? createdOn,
    String? workLocation,
    String? shiftType,
    String? supervisorId,
    double? salaryRate,
    String? emergencyContact,
    String? emergencyPhone,
    bool? biometricEnabled,
    String? preferredLanguage,
    bool? notificationsEnabled,
    int? totalCoverageGiven,
    int? totalCoverageReceived,
    double? attendanceRate,
    int? leaveBalance,
  }) {
    return UserModel(
      uId: uId ?? this.uId,
      employeeId: employeeId ?? this.employeeId,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userImg: userImg ?? this.userImg,
      userDeviceToken: userDeviceToken ?? this.userDeviceToken,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      position: position ?? this.position,
      userRole: userRole ?? this.userRole,
      isActive: isActive ?? this.isActive,
      createdOn: createdOn ?? this.createdOn,
      workLocation: workLocation ?? this.workLocation,
      shiftType: shiftType ?? this.shiftType,
      supervisorId: supervisorId ?? this.supervisorId,
      salaryRate: salaryRate ?? this.salaryRate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      totalCoverageGiven: totalCoverageGiven ?? this.totalCoverageGiven,
      totalCoverageReceived: totalCoverageReceived ?? this.totalCoverageReceived,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      leaveBalance: leaveBalance ?? this.leaveBalance,
    );
  }

  @override
  String toString() {
    return 'UserModel(employeeId: $employeeId, fullName: $fullName, department: $department, role: $userRole)';
  }
}