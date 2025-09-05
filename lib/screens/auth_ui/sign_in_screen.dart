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
import 'forget_password_screen.dart';
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
      curve: Curves.elasticOut,
    ));
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConstant.gradientStart,
                  AppConstant.gradientEnd,
                  AppConstant.primaryColor,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: Get.height - MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      SizedBox(height: isKeyboardVisible ? 40 : 80),
                      
                      // Logo and Welcome Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Logo Container with Beautiful Effects
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
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
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: AppConstant.secondaryColor.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 5,
                                      offset: Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/logo/tanainent_logo.png',
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
                                  'Sign in to continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isKeyboardVisible ? 30 : 50),

                      // Form Card
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, -5),
                              ),
                            ],
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

                              SizedBox(height: 20),

                              // Password Field
                              Obx(() => _buildPasswordField()),

                              SizedBox(height: 10),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Get.to(() => ForgetPasswordScreen()),
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
                                      color: AppConstant.appTextColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.to(() => SignUpScreen()),
                                    child: Text(
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        color: AppConstant.backgroundColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppConstant.backgroundColor.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: const Color.fromARGB(255, 0, 0, 0),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
          ),
          prefixIcon: Icon(
            icon,
            color: AppConstant.secondaryColor.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstant.backgroundColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppConstant.backgroundColor.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: userPassword,
        obscureText: !signInController.isPasswordVisible.value,
        style: TextStyle(
          color: const Color.fromARGB(255, 0, 0, 0),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AppConstant.secondaryColor.withOpacity(0.7),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              signInController.isPasswordVisible.toggle();
            },
            icon: Icon(
              signInController.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppConstant.secondaryColor.withOpacity(0.7),
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      return;
    }

    try {
      Map<String, dynamic> result = await signInController.signInMethod(email, password);

      if (result['success'] == true) {
        AuthResponse authResponse = result['authResponse'];
        
        // For Supabase, email verification status is already checked in controller
        try {
          // Get the complete user model
          UserModel? userModel = await getUserDataController
              .getUserModel(authResponse.user!.id);
          
          // If user model doesn't exist, create it automatically
          if (userModel == null) {
            print('User profile not found, creating default profile...');
            
            // Create a default user profile from auth data
            final authUser = authResponse.user!;
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

            // Try to create the user profile
            final success = await getUserDataController.createUserModel(defaultUserModel);
            
            if (success) {
              userModel = defaultUserModel;
              print('Default user profile created successfully');
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.snackbar(
                  "Error",
                  "Failed to create user profile. Please contact support.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppConstant.errorColor,
                  colorText: Colors.white,
                  borderRadius: 15,
                  margin: EdgeInsets.all(15),
                );
              });
              return;
            }
          }
          
          // At this point, userModel should not be null
          if (userModel != null) {
            if (userModel.isAdmin) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.snackbar(
                  "Success",
                  "Admin login successful!",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppConstant.successColor,
                  colorText: Colors.white,
                  borderRadius: 15,
                  margin: EdgeInsets.all(15),
                );
                // Navigate to admin screen
                Get.offAllNamed('/admin', arguments: userModel);
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.snackbar(
                  "Success",
                  "Login successful!",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppConstant.successColor,
                  colorText: Colors.white,
                  borderRadius: 15,
                  margin: EdgeInsets.all(15),
                );
                Get.offAll(() => LandingScreen(userModel: userModel!));
              });
            }
          }
        } catch (e) {
          print('Error loading user profile: $e');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(
              "Error",
              "Failed to load user profile: ${e.toString()}",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppConstant.errorColor,
              colorText: Colors.white,
              borderRadius: 15,
              margin: EdgeInsets.all(15),
            );
          });
        }
      } else {
        // Show the specific error message from the controller
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            "Error",
            result['message'],
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstant.errorColor,
            colorText: Colors.white,
            borderRadius: 15,
            margin: EdgeInsets.all(15),
            duration: Duration(seconds: 5), // Show longer for verification messages
          );
        });
      }
    } catch (e) {
      print('Sign in error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          "Error",
          "An error occurred during sign in: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
          borderRadius: 15,
          margin: EdgeInsets.all(15),
        );
      });
    }
  }
}
