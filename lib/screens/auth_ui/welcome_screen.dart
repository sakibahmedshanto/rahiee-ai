import 'dart:ui';

import 'sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import '../../../controllers/auth_controller/google_sign_in_controller.dart';
import '../../utils/app_constant.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  // final GoogleSignInController _googleSignInController =
  //     Get.put(GoogleSignInController());
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    requestNotificationPermissions();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void requestNotificationPermissions() async {
    // For Supabase projects, you can implement push notifications using:
    // 1. FCM (Firebase Cloud Messaging) as a separate service
    // 2. Supabase Edge Functions with push notification providers
    // 3. Third-party notification services
    
    // For now, we'll skip notification permissions during migration
    // TODO: Implement notification system with Supabase Edge Functions
    try {
      print('Notification permissions will be implemented with Supabase Edge Functions');
    } catch (e) {
      print('Error with notification setup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _buildAuraCircle(180, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _buildAuraCircle(220, AppConstant.secondaryColor.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -90,
            right: -30,
            child: _buildAuraCircle(180, Colors.white.withOpacity(0.05)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: Get.height - MediaQuery.of(context).padding.top,
                child: Column(
                  children: [
                    // Logo and Branding Section
                    Expanded(
                      flex: 5,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated Logo Container
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      padding: EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.95),
                                            Colors.white.withOpacity(0.75),
                                            AppConstant.backgroundColor.withOpacity(0.85),
                                          ],
                                          stops: [0.0, 0.4, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.65),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.35),
                                            blurRadius: 35,
                                            spreadRadius: 10,
                                          ),
                                          BoxShadow(
                                            color: AppConstant.secondaryColor.withOpacity(0.1),
                                            blurRadius: 25,
                                            offset: Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/logo/tanainent_logo.png',
                                        height: Get.height * 0.15,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              SizedBox(height: 22),
                              
                              // Brand Name
                              Text(
                                AppConstant.appMainName,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: Offset(0, 3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 10),
                              
                              // Tagline
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28),
                                child: Text(
                                  "A refined workspace companion for visionary teams.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.88),
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Action Button Section
                    Expanded(
                      flex: 4,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildEmailSignInButton(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildGoogleSignInButton() {
  //   return Container(
  //     width: double.infinity,
  //     height: 56,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(15),
  //       border: Border.all(
  //         color: Colors.grey.withOpacity(0.3),
  //         width: 1.5,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 15,
  //           offset: Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(15),
  //         onTap: () async {
  //           bool success = await _googleSignInController.signInWithGoogle();
  //           if (!success) {
  //             Get.snackbar(
  //               'Error',
  //               'Failed to sign in with Google. Please try again.',
  //               snackPosition: SnackPosition.BOTTOM,
  //               backgroundColor: AppConstant.errorColor,
  //               colorText: Colors.white,
  //               borderRadius: 15,
  //               margin: EdgeInsets.all(15),
  //             );
  //           }
  //         },
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Image.asset(
  //               'assets/icons/google_icon.png',
  //               width: 24,
  //               height: 24,
  //             ),
  //             SizedBox(width: 15),
  //             Text(
  //               "Continue with Google",
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppConstant.textPrimary,
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAuraCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildEmailSignInButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.32),
            Colors.white.withOpacity(0.18),
            AppConstant.secondaryColor.withOpacity(0.75),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstant.secondaryColor.withOpacity(0.28),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            Get.to(
              () => const SignInScreen(),
              transition: Transition.rightToLeftWithFade,
              duration: Duration(milliseconds: 350),
            );
          },
          child: Stack(
            children: [
              Positioned(
                right: 18,
                top: 14,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Sign in with Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 14),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
