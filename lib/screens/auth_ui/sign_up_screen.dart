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

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final SignUpController signUpController = Get.put(SignUpController());
  TextEditingController username = TextEditingController();
  TextEditingController userEmail = TextEditingController();
  TextEditingController userPhone = TextEditingController();
  TextEditingController userCity = TextEditingController();
  TextEditingController userPassword = TextEditingController();

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
                constraints: BoxConstraints(
                  minHeight: Get.height - MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  children: [
                    // Elegant Header Section
                    Container(
                      height: isKeyboardVisible ? 120 : 220,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                  height: isKeyboardVisible ? 40 : 70,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (!isKeyboardVisible) ...[
                                SizedBox(height: 10),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                            
                                Text(
                                  'Join us and start your journey',
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
                    SlideTransition(
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
                          padding: EdgeInsets.all(25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Form Title
                              Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstant.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 25),
                              
                              // Email Field
                              _buildInputField(
                                controller: userEmail,
                                hint: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: 15),
                              
                              // Username Field
                              _buildInputField(
                                controller: username,
                                hint: 'Full Name',
                                icon: Icons.person_outline,
                                keyboardType: TextInputType.name,
                              ),
                              SizedBox(height: 15),
                              
                              // Phone Field
                              _buildInputField(
                                controller: userPhone,
                                hint: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 15),
                              
                              // City Field
                              _buildInputField(
                                controller: userCity,
                                hint: 'City',
                                icon: Icons.location_on_outlined,
                                keyboardType: TextInputType.text,
                              ),
                              SizedBox(height: 15),
                              
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
                              
                              SizedBox(height: 30),
                              
                              // Sign Up Button
                              _buildSignUpButton(),
                              
                              SizedBox(height: 25),
                              
                              // Sign In Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: AppConstant.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.offAll(() => SignInScreen(),
                                        transition: Transition.leftToRight,
                                        duration: Duration(milliseconds: 300)),
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
                              SizedBox(height: 20),
                            ],
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
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
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
        obscureText: obscureText,
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
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
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
          onTap: _handleSignUp,
          child: Center(
            child: Text(
              'SIGN UP',
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

  Future<void> _handleSignUp() async {
    String name = username.text.trim();
    String email = userEmail.text.trim();
    String phone = userPhone.text.trim();
    String city = userCity.text.trim();
    String password = userPassword.text.trim();
    String userDeviceToken = '';

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        city.isEmpty ||
        password.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter all details",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        borderRadius: 15,
        margin: EdgeInsets.all(15),
      );
    } else {
      Map<String, dynamic> result =
          await signUpController.signUpMethod(
        name,
        email,
        phone,
        city,
        password,
        userDeviceToken,
      );

      if (result['success'] == true) {
        // Sign out to ensure clean state
        await Supabase.instance.client.auth.signOut();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            "Success",
            result['message'],
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstant.successColor,
            colorText: Colors.white,
            borderRadius: 15,
            margin: EdgeInsets.all(15),
            duration: Duration(seconds: 5), // Show longer since it's important
          );
          
          // Navigate to sign-in screen
          Get.offAll(() => SignInScreen(),
              transition: Transition.leftToRight,
              duration: Duration(milliseconds: 300));
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            "Error",
            result['message'],
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstant.errorColor,
            colorText: Colors.white,
            borderRadius: 15,
            margin: EdgeInsets.all(15),
            duration: Duration(seconds: 4), // Show error longer for better readability
          );
        });
      }
    }
  }
}
