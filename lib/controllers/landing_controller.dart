// ignore_for_file: file_names

import 'package:get/get.dart';
import '../models/user_model.dart';

class LandingController extends GetxController {
  late UserModel userModel;
  final RxBool isLoading = false.obs;

  void initializeWithUser(UserModel user) {
    userModel = user;
  }
  void onLogoutPressed() {
    // TODO: Implement logout functionality
    Get.snackbar('Logout', 'Logout functionality will be implemented soon');
  }

  String get welcomeMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String get userDisplayName {
    return userModel.fullName.isNotEmpty ? userModel.fullName : userModel.username;
  }

  String get userPosition {
    return userModel.position;
  }

  String get userDepartment {
    return userModel.department;
  }

  String get userRole {
    return userModel.userRole.toUpperCase();
  }

  String get userEmployeeId {
    return userModel.employeeId;
  }

  String get userEmail {
    return userModel.email;
  }

  String get userPhone {
    return userModel.phone;
  }

  String? get userImage {
    return userModel.userImg;
  }
}
