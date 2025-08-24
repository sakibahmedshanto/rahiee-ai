// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable, file_names

import '../../utils/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller/forget_password_controller.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> with TickerProviderStateMixin {
  final ForgerPasswordController forgerPasswordController =
      Get.put(ForgerPasswordController());
  TextEditingController userEmail = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return Scaffold(
        backgroundColor: AppConstant.backgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstant.gradientStart,
                AppConstant.gradientEnd,
                AppConstant.primaryColor,
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: Get.height - MediaQuery.of(context).padding.top,
                child: Column(
                  children: [
                    // Elegant Header Section
                    Expanded(
                      flex: isKeyboardVisible ? 1 : 2,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Back Button
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () => Get.back(),
                                      icon: Icon(
                                        Icons.arrow_back_ios_new,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
                              
                              if (!isKeyboardVisible) SizedBox(height: 20),
                              
                              // Logo/Brand Section
                              Container(
                                padding: EdgeInsets.all(isKeyboardVisible ? 15 : 20),
                                decoration: BoxDecoration(
                                  // Beautiful gradient background for the logo
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.85),
                                      AppConstant.backgroundColor.withOpacity(0.9),
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    // Outer glow effect
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 25,
                                      spreadRadius: 5,
                                    ),
                                    // Inner shadow for depth
                                    BoxShadow(
                                      color: AppConstant.secondaryColor.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
                                    // Subtle top highlight
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 5,
                                      offset: Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/logo/tanainent_logo.png',
                                  height: isKeyboardVisible ? 50 : 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              
                              if (!isKeyboardVisible) ...[
                                SizedBox(height: 25),
                                Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Enter your email to receive reset instructions',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Form Section
                    Expanded(
                      flex: 2,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstant.cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(35),
                              topRight: Radius.circular(35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstant.shadowColor,
                                blurRadius: 30,
                                offset: Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form Title
                                Text(
                                  'Forgot Password',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstant.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Don\'t worry! It happens. Please enter the email address linked with your account.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstant.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 30),
                                
                                // Email Field
                                _buildInputField(
                                  controller: userEmail,
                                  hint: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                
                                SizedBox(height: 30),
                                
                                // Reset Button
                                _buildResetButton(),
                                
                                SizedBox(height: 25),
                                
                                // Back to Sign In
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Remember your password? ",
                                      style: TextStyle(
                                        color: AppConstant.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Get.back(),
                                      child: Text(
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstant.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppConstant.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppConstant.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: AppConstant.secondaryColor,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstant.gradientStart, AppConstant.gradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppConstant.secondaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _handleResetPassword,
          child: Center(
            child: Text(
              'SEND RESET LINK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    String email = userEmail.text.trim();

    if (email.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter your email address",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        borderRadius: 15,
        margin: EdgeInsets.all(15),
      );
    } else {
      forgerPasswordController.ForgetPasswordMethod(email);
    }
  }
}
