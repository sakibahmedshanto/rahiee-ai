import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rahiee_ai/controllers/admin_controllers/admin_controller.dart';
import 'services/supabase_service.dart';
import 'services/schedule_service.dart';
import 'services/attendance_management_service.dart';
import 'services/location_permission_service.dart';
import 'services/uniform_verification_service.dart';
import 'services/photo_storage_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/notification_history_service.dart';
import 'services/notification_integration_service.dart';
import 'screens/auth_ui/splash_screen/splash_screen.dart';
import 'screens/auth_ui/welcome_screen.dart';
import 'screens/admin/admin_screen/admin_screen.dart';
import 'screens/auth_ui/sign_in_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/app_constant.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase in a single place with proper error handling
  await SupabaseService.initialize();

  // Initialize services
  Get.put(SupabaseService());
  Get.put(ScheduleService());
  Get.put(AttendanceManagementService());
  Get.put(LocationPermissionService());
  Get.put(UniformVerificationService());
  Get.put(PhotoStorageService());
  Get.put(FCMService());
  Get.put(NotificationService());
  Get.put(NotificationHistoryService());
  Get.put(NotificationIntegrationService());
  Get.put(ThemeController());
  Get.put(AdminController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstant.appMainName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
      builder: EasyLoading.init(),
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/admin', page: () => const AdminScreen()),
        GetPage(name: '/sign-in', page: () => const SignInScreen()),
      ],
    );
  }
}
