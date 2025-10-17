// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable, unnecessary_null_comparison, file_names

import '../../../controllers/auth_controller/sign_in_controller.dart';
import 'sign_up_screen.dart';
import '../../utils/app_constant.dart';
import '../../models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/auth_controller/get_user_data_controller.dart';
import '../../../services/fcm_service.dart';
import 'forget_password_screen.dart';
import '../landing_screen/landing_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final SignInController signInController = Get.put(SignInController());
  final GetUserDataController getUserDataController =
      Get.put(GetUserDataController());
  final FCMService fcmService = Get.find<FCMService>();
  
  // Use late initialization for better performance
  late final TextEditingController userEmail;
  late final TextEditingController userPassword;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Pre-built static widgets for better performance
  static const _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppConstant.gradientStart,
      AppConstant.gradientEnd,
      AppConstant.primaryColor,
    ],
    stops: [0.0, 0.7, 1.0],
  );

  @override
  void initState() {
    super.initState();
    userEmail = TextEditingController();
    userPassword = TextEditingController();
    
    // Faster, simpler animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start animation immediately
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    userEmail.dispose();
    userPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: _backgroundGradient),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = isKeyboardVisible || constraints.maxHeight < 600;
                  
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(height: isCompact ? 20 : 60),
                            
                            // Logo and Welcome Section
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildLogoSection(isCompact),
                            ),

                            SizedBox(height: isCompact ? 20 : 40),

                            // Form Card
                            Expanded(
                              child: _buildFormCard(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(bool isCompact) {
    return Column(
      children: [
        // Simplified logo container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/logo/tanainent_logo.png',
            height: isCompact ? 50 : 80,
            fit: BoxFit.contain,
          ),
        ),
        
        if (!isCompact) ...[
          const SizedBox(height: 24),
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          _buildInputField(
            controller: userEmail,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // Password Field
          Obx(() => _buildPasswordField()),

          const SizedBox(height: 8),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.to(() => const ForgetPasswordScreen()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppConstant.secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sign In Button
          _buildSignInButton(),

          const SizedBox(height: 24),

          // Sign Up Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: AppConstant.appTextColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => Get.to(() => const SignUpScreen()),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppConstant.secondaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            icon,
            color: AppConstant.secondaryColor,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: userPassword,
        obscureText: !signInController.isPasswordVisible.value,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppConstant.secondaryColor,
            size: 20,
          ),
          suffixIcon: IconButton(
            onPressed: signInController.isPasswordVisible.toggle,
            icon: Icon(
              signInController.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppConstant.secondaryColor,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstant.secondaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppConstant.secondaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'SIGN IN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = userEmail.text.trim();
    final password = userPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar(
        "Error",
        "Please enter all details",
        AppConstant.errorColor,
      );
      return;
    }

    try {
      final result = await signInController.signInMethod(email, password);

      if (result['success'] == true) {
        final AuthResponse authResponse = result['authResponse'];
        
        try {
          // Get user model efficiently
          UserModel? userModel = await getUserDataController
              .getUserModel(authResponse.user!.id);
          
          // Create default profile if needed
          if (userModel == null) {
            userModel = await _createDefaultUserProfile(authResponse.user!, email);
            if (userModel == null) {
              _showSnackbar(
                "Error",
                "Failed to create user profile. Please contact support.",
                AppConstant.errorColor,
              );
              return;
            }
          }
          
          // Save device token for push notifications
          try {
            await fcmService.saveDeviceTokenForUser(authResponse.user!.id);
          } catch (e) {
            // Don't block sign-in if device token saving fails
            print('Failed to save device token: $e');
          }
          
          // Navigate based on user role
          _navigateToApp(userModel);
          
        } catch (e) {
          _showSnackbar(
            "Error",
            "Failed to load user profile: ${e.toString()}",
            AppConstant.errorColor,
          );
        }
      } else {
        _showSnackbar(
          "Error",
          result['message'],
          AppConstant.errorColor,
          duration: 5,
        );
      }
    } catch (e) {
      _showSnackbar(
        "Error",
        "An error occurred during sign in: ${e.toString()}",
        AppConstant.errorColor,
      );
    }
  }

  Future<UserModel?> _createDefaultUserProfile(User authUser, String email) async {
    final defaultUserModel = UserModel(
      uId: authUser.id,
      employeeId: 'EMP-${authUser.id.substring(0, 8).toUpperCase()}',
      username: authUser.userMetadata?['full_name'] ?? email.split('@')[0],
      email: authUser.email ?? email,
      phone: authUser.userMetadata?['phone'] ?? '',
      fullName: authUser.userMetadata?['full_name'] ?? email.split('@')[0],
      department: 'General',
      position: 'Employee',
      userRole: 'employee',
      userImg: null,
      userDeviceToken: null,
      isActive: true,
      createdOn: DateTime.now(),
      workLocation: authUser.userMetadata?['city'],
      biometricEnabled: false,
      notificationsEnabled: true,
      preferredLanguage: 'en',
      leaveBalance: 30,
      totalCoverageGiven: 0,
      totalCoverageReceived: 0,
      attendanceRate: 100.0,
    );

    final success = await getUserDataController.createUserModel(defaultUserModel);
    return success ? defaultUserModel : null;
  }

  void _navigateToApp(UserModel userModel) {
    if (userModel.isAdmin) {
      _showSnackbar(
        "Success",
        "Admin login successful!",
        AppConstant.successColor,
      );
      Get.offAllNamed('/admin', arguments: userModel);
    } else {
      _showSnackbar(
        "Success",
        "Login successful!",
        AppConstant.successColor,
      );
      Get.offAll(() => LandingScreen(userModel: userModel));
    }
  }

  void _showSnackbar(String title, String message, Color color, {int duration = 3}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: duration),
      );
    });
  }
}
