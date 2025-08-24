// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../../../../utils/app_constant.dart';

class AnimatedLoadingText extends StatefulWidget {
  const AnimatedLoadingText({super.key});

  @override
  State<AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation controller for dots
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
  }

  void _startAnimations() {
    // Start fade animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    // Start pulse animation for dots
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated dots only (loading text is commented out)
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final delay = index * 0.3;
                      final animationValue = (_pulseController.value + delay) % 1.0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ".",
                          style: TextStyle(
                            color: AppConstant.primaryColor.withOpacity(
                              0.3 + 0.7 * animationValue,
                            ),
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
