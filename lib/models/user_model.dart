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
  final dynamic createdOn;
  final dynamic lastLogin; // Optional last login timestamp
  
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
    required this.createdOn,
    this.userImg,
    this.userDeviceToken,
    this.lastLogin,
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

  // Serialize the UserModel instance to a JSON map
  Map<String, dynamic> toMap() {
    return {
      'uId': uId,
      'employeeId': employeeId,
      'username': username,
      'email': email,
      'phone': phone,
      'userImg': userImg,
      'userDeviceToken': userDeviceToken,
      'fullName': fullName,
      'department': department,
      'position': position,
      'userRole': userRole,
      'isActive': isActive,
      'createdOn': createdOn,
      'lastLogin': lastLogin,
      'workLocation': workLocation,
      'shiftType': shiftType,
      'supervisorId': supervisorId,
      'salaryRate': salaryRate,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'biometricEnabled': biometricEnabled,
      'preferredLanguage': preferredLanguage,
      'notificationsEnabled': notificationsEnabled,
      'totalCoverageGiven': totalCoverageGiven,
      'totalCoverageReceived': totalCoverageReceived,
      'attendanceRate': attendanceRate,
      'leaveBalance': leaveBalance,
    };
  }

  // Create a UserModel instance from a JSON map
  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      uId: json['uId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? '',
      userRole: json['userRole'] ?? 'employee',
      isActive: json['isActive'] ?? true,
      createdOn: json['createdOn'],
      userImg: json['userImg'],
      userDeviceToken: json['userDeviceToken'],
      lastLogin: json['lastLogin'],
      workLocation: json['workLocation'],
      shiftType: json['shiftType'],
      supervisorId: json['supervisorId'],
      salaryRate: json['salaryRate']?.toDouble(),
      emergencyContact: json['emergencyContact'],
      emergencyPhone: json['emergencyPhone'],
      biometricEnabled: json['biometricEnabled'],
      preferredLanguage: json['preferredLanguage'],
      notificationsEnabled: json['notificationsEnabled'],
      totalCoverageGiven: json['totalCoverageGiven']?.toInt(),
      totalCoverageReceived: json['totalCoverageReceived']?.toInt(),
      attendanceRate: json['attendanceRate']?.toDouble(),
      leaveBalance: json['leaveBalance']?.toInt(),
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
    dynamic createdOn,
    dynamic lastLogin,
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
      lastLogin: lastLogin ?? this.lastLogin,
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