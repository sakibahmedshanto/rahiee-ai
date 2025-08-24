// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable, unnecessary_null_comparison, file_names

import '../../../controllers/auth_controller/sign_in_controller.dart';
import 'sign_up_screen.dart';
import '../../utils/app_constant.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller/get_user_data_controller.dart';
import 'forget_password_screen.dart';
import '../admin/admin_screen.dart';
import '../landing_screen/landing_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final SignInController signInController = Get.put(SignInController());
  final GetUserDataController getUserDataController =
      Get.put(GetUserDataController());
  TextEditingController userEmail = TextEditingController();
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
                              // Logo/Brand Section
                              Container(
                                padding: EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  // Beautiful gradient background for the logo
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.85),
                                      AppConstant.backgroundColor
                                          .withOpacity(0.9),
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    // Outer glow effect
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                    ),
                                    // Inner shadow for depth
                                    BoxShadow(
                                      color: AppConstant.secondaryColor
                                          .withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
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
                                  'assets/images/logo.png',
                                  height: isKeyboardVisible ? 60 : 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (!isKeyboardVisible) ...[
                                SizedBox(height: 30),
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Sign in to continue your journey',
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
                      flex: 3,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstant.cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
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
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstant.textPrimary,
                                    letterSpacing: 0.5,
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
                                SizedBox(height: 20),

                                // Password Field
                                Obx(() => _buildInputField(
                                      controller: userPassword,
                                      hint: 'Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: signInController
                                          .isPasswordVisible.value,
                                      suffixIcon: GestureDetector(
                                        onTap: () => signInController
                                            .isPasswordVisible
                                            .toggle(),
                                        child: Icon(
                                          signInController
                                                  .isPasswordVisible.value
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppConstant.textSecondary,
                                        ),
                                      ),
                                    )),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        Get.to(() => ForgetPasswordScreen()),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppConstant.secondaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Sign In Button
                                _buildSignInButton(),

                                SizedBox(height: 30),

                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: AppConstant.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Get.to(() => SignUpScreen(),
                                          transition: Transition.rightToLeft,
                                          duration:  Duration(milliseconds: 300)),
                                      child: Text(
                                        "Sign Up",
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

  Widget _buildSignInButton() {
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
          onTap: _handleSignIn,
          child: Center(
            child: Text(
              'SIGN IN',
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

  Future<void> _handleSignIn() async {
    String email = userEmail.text.trim();
    String password = userPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
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
      UserCredential? userCredential =
          await signInController.signInMethod(email, password);

      if (userCredential != null) {
        var userData =
            await getUserDataController.getUserData(userCredential.user!.uid);

        if (userCredential.user!.emailVerified) {
          if (userData[0]['isAdmin'] == true) {
            Get.snackbar(
              "Success",
              "Admin login successful!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppConstant.successColor,
              colorText: Colors.white,
              borderRadius: 15,
              margin: EdgeInsets.all(15),
            );
            Get.offAll(() => AdminScreen());
          } else {
            UserModel? userModel = await getUserDataController
                .getUserModel(userCredential.user!.uid);
            Get.offAll(() => LandingScreen(userModel: userModel!));
            Get.snackbar(
              "Success",
              "Login successful!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppConstant.successColor,
              colorText: Colors.white,
              borderRadius: 15,
              margin: EdgeInsets.all(15),
            );
          }
        } else {
          Get.snackbar(
            "Error",
            "Please verify your email before login",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstant.errorColor,
            colorText: Colors.white,
            borderRadius: 15,
            margin: EdgeInsets.all(15),
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Please try again",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
          borderRadius: 15,
          margin: EdgeInsets.all(15),
        );
      }
    }
  }
}
