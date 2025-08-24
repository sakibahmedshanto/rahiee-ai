import 'sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../controllers/auth_controller/google_sign_in_controller.dart';
import '../../utils/app_constant.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final GoogleSignInController _googleSignInController =
      Get.put(GoogleSignInController());
  
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
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Container(
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
                                    padding: EdgeInsets.all(25),
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
                                          color: AppConstant.secondaryColor.withOpacity(0.1),
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
                                      'assets/logo/tanainent_logo.png',
                                      height: Get.height * 0.15,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Brand Name
                            Text(
                              AppConstant.appMainName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 8),
                            
                            // Tagline
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                "Find your home in Augmented Reality",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                  height: 1.2,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Action Buttons Section
                  Expanded(
                    flex: 4,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 25,
                              offset: Offset(0, -8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Welcome Text
                              Text(
                                "Welcome to the Future",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstant.textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              
                              SizedBox(height: 6),
                              
                              Text(
                                "Choose your preferred sign-in method",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppConstant.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              
                              SizedBox(height: 25),
                              
                              // Google Sign In Button
                              _buildGoogleSignInButton(),
                              
                              SizedBox(height: 12),
                              
                              // Email Sign In Button
                              _buildEmailSignInButton(),
                              
                              SizedBox(height: 15),
                              
                              // Terms and Privacy
                              Text(
                                "By continuing, you agree to our Terms of Service\nand Privacy Policy",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppConstant.textSecondary,
                                  height: 1.2,
                                ),
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
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            _googleSignInController.signInWithGoogle();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/google_icon.png',
                width: 24,
                height: 24,
              ),
              SizedBox(width: 15),
              Text(
                "Continue with Google",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstant.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSignInButton() {
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
          onTap: () {
            Get.to(() => const SignInScreen(),
                transition: Transition.rightToLeft,
                duration: Duration(milliseconds: 300)
                );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 15),
              Text(
                "Continue with Email",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
