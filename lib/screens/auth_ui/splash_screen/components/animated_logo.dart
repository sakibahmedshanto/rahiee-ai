// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/app_constant.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Main logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Rotate animation controller
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotate animation
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));
  }

  void _startAnimations() {
    _logoController.forward();
    
    // Start pulse animation after logo appears
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    // Start rotate animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _rotateController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // Getter to expose fade animation for external use
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get pulseAnimation => _pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _scaleAnimation,
        _pulseAnimation,
        _rotateAnimation,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Container(
              width: Get.width / 1.2,
              height: Get.width / 1.2,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating background circle
                  Transform.rotate(
                    angle: _rotateAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: Get.width / 1.5,
                      height: Get.width / 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppConstant.primaryColor.withOpacity(0.1),
                            AppConstant.secondaryColor.withOpacity(0.3),
                            AppConstant.accentColor.withOpacity(0.1),
                            AppConstant.primaryColor.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Glowing outer ring
                  Container(
                    width: Get.width / 1.8,
                    height: Get.width / 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstant.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstant.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  
                  // Logo container with beautiful background
                  Container(
                    width: Get.width / 2.2,
                    height: Get.width / 2.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          AppConstant.backgroundColor,
                          AppConstant.surfaceColor,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstant.primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/logo/tanainent_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
