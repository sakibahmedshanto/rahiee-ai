import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';
  
  // Observable theme mode
  var isDarkMode = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }
  
  // Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkMode.value = prefs.getBool(_themeKey) ?? false;
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }
  
  // Toggle theme and save preference
  Future<void> toggleTheme() async {
    try {
      isDarkMode.value = !isDarkMode.value;
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode.value);
      
      // Show feedback
      Get.snackbar(
        'Theme Changed',
        isDarkMode.value ? 'Dark mode activated' : 'Light mode activated',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        backgroundColor: isDarkMode.value 
            ? Color(0xFF1F2937) 
            : Color(0xFFFFFFFF),
        colorText: isDarkMode.value 
            ? Color(0xFFF9FAFB) 
            : Color(0xFF1F2937),
        margin: EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(
          isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode.value 
              ? Color(0xFF6EE7B7) 
              : Color(0xFF10B981),
        ),
      );
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
  
  // Get current theme colors
  Color get primaryColor => isDarkMode.value 
      ? Color(0xFF6EE7B7) 
      : Color(0xFF10B981);
      
  Color get secondaryColor => isDarkMode.value 
      ? Color(0xFFFBBF24) 
      : Color(0xFFF59E0B);
      
  Color get backgroundColor => isDarkMode.value 
      ? Color(0xFF0F0F23) 
      : Color(0xFFF8FAFC);
      
  Color get surfaceColor => isDarkMode.value 
      ? Color(0xFF1F2937) 
      : Color(0xFFFFFFFF);
      
  Color get textColor => isDarkMode.value 
      ? Color(0xFFF9FAFB) 
      : Color(0xFF1F2937);
      
  Color get textSecondaryColor => isDarkMode.value 
      ? Color(0xFFD1D5DB) 
      : Color(0xFF6B7280);
      
  Color get borderColor => isDarkMode.value 
      ? Color(0xFF4B5563) 
      : Color(0xFFE2E8F0);
      
  Color get shadowColor => isDarkMode.value 
      ? Color(0x4D000000) 
      : Color(0x1A0F0F23);
      
  // Gradient colors
  List<Color> get primaryGradient => isDarkMode.value 
      ? [Color(0xFF6EE7B7), Color(0xFF047857)]
      : [Color(0xFF10B981), Color(0xFF059669)];
      
  List<Color> get secondaryGradient => isDarkMode.value 
      ? [Color(0xFFFBBF24), Color(0xFFD97706)]
      : [Color(0xFFF59E0B), Color(0xFFD97706)];
}
