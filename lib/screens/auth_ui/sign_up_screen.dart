// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, file_names, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/auth_controller/sign_up_controller.dart';
import '../../utils/app_constant.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final SignUpController signUpController = Get.put(SignUpController());
  
  // Use late initialization for better performance
  late final TextEditingController username;
  late final TextEditingController userEmail;
  late final TextEditingController userPhone;
  late final TextEditingController userCity;
  late final TextEditingController userPassword;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Pre-built static widgets for better performance
  static const _backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppConstant.gradientStart,
      AppConstant.gradientEnd,
      AppConstant.primaryColor,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const _logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF2FFFFFF),
      Color(0xD9FFFFFF),
      Color(0xE6FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  void initState() {
    super.initState();
    username = TextEditingController();
    userEmail = TextEditingController();
    userPhone = TextEditingController();
    userCity = TextEditingController();
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
    username.dispose();
    userEmail.dispose();
    userPhone.dispose();
    userCity.dispose();
    userPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return Scaffold(
        backgroundColor: AppConstant.backgroundColor,
        body: Container(
          decoration: const BoxDecoration(gradient: _backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                            MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  children: [
                    // Optimized Header Section
                    _buildHeaderSection(isKeyboardVisible),
                    
                    // Optimized Form Section
                    _buildFormSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderSection(bool isKeyboardVisible) {
    final headerHeight = isKeyboardVisible ? 120.0 : 200.0;
    
    return SizedBox(
      height: headerHeight,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optimized Logo Container
              Container(
                padding: EdgeInsets.all(isKeyboardVisible ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: _logoGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo/tanainent_logo.png',
                  height: isKeyboardVisible ? 36 : 60,
                  fit: BoxFit.contain,
                ),
              ),
              
              if (!isKeyboardVisible) ...[
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join us and start your journey',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstant.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Title
            const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppConstant.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Email Field
            _buildInputField(
              controller: userEmail,
              hint: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Username Field
            _buildInputField(
              controller: username,
              hint: 'Full Name',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            
            // Phone Field
            _buildInputField(
              controller: userPhone,
              hint: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // City Field
            _buildInputField(
              controller: userCity,
              hint: 'City',
              icon: Icons.location_on_outlined,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            
            // Password Field
            Obx(() => _buildInputField(
              controller: userPassword,
              hint: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: signUpController.isPasswordVisible.value,
              suffixIcon: GestureDetector(
                onTap: () => signUpController.isPasswordVisible.toggle(),
                child: Icon(
                  signUpController.isPasswordVisible.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppConstant.textSecondary,
                ),
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Sign Up Button
            _buildSignUpButton(),
            
            const SizedBox(height: 20),
            
            // Sign In Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(
                    color: AppConstant.textSecondary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.offAll(() => const SignInScreen(),
                      transition: Transition.leftToRight,
                      duration: const Duration(milliseconds: 250)),
                  child: const Text(
                    "Sign In",
                    style: TextStyle(
                      color: AppConstant.secondaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstant.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppConstant.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppConstant.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: AppConstant.secondaryColor,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstant.gradientStart, AppConstant.gradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppConstant.secondaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleSignUp,
          child: const Center(
            child: Text(
              'SIGN UP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    // Get trimmed values once
    final name = username.text.trim();
    final email = userEmail.text.trim();
    final phone = userPhone.text.trim();
    final city = userCity.text.trim();
    final password = userPassword.text.trim();

    // Quick validation
    if (name.isEmpty || email.isEmpty || phone.isEmpty || city.isEmpty || password.isEmpty) {
      _showErrorSnackbar("Please enter all details");
      return;
    }

    try {
      final result = await signUpController.signUpMethod(
        name,
        email,
        phone,
        city,
        password,
        '', // userDeviceToken
      );

      if (result['success'] == true) {
        // Sign out to ensure clean state
        await Supabase.instance.client.auth.signOut();
        
        // Show success message and navigate
        if (mounted) {
          _showSuccessSnackbar(result['message'] ?? 'Account created successfully!');
          
          // Navigate to sign-in screen
          Get.offAll(() => const SignInScreen(),
              transition: Transition.leftToRight,
              duration: const Duration(milliseconds: 250));
        }
      } else {
        if (mounted) {
          _showErrorSnackbar(result['message'] ?? 'Sign up failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('An error occurred during sign up. Please try again.');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppConstant.errorColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      "Success",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppConstant.successColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }
}
