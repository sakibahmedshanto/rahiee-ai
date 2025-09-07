import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/schedule_service.dart';
import 'services/attendance_management_service.dart';
import 'services/location_permission_service.dart';
import 'screens/auth_ui/splash_screen/splash_screen.dart';
import 'screens/auth_ui/welcome_screen.dart';
import 'screens/schedule_screen/schedule_screen.dart';
import 'screens/admin/admin_screen/new_admin_screen.dart';
import 'screens/auth_ui/sign_in_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/app_constant.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase first
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );
  
  // Initialize services
  Get.put(SupabaseService());
  Get.put(ScheduleService());
  Get.put(AttendanceManagementService());
  Get.put(LocationPermissionService());
  
  // Initialize theme controller
  Get.put(ThemeController());
  
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
        GetPage(name: '/schedule', page: () => const ScheduleScreen()),
        GetPage(name: '/admin', page: () => const AdminScreen()),
        GetPage(name: '/sign-in', page: () => const SignInScreen()),
      ],
    );
  }
}
