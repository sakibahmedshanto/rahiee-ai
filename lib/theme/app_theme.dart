import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // 🌟 LIGHT THEME - Midnight Elegance
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        // Primary Colors
        primary: Color(0xFF10B981), // Emerald Green
        onPrimary: Color(0xFFFFFFFF), // White
        primaryContainer: Color(0xFFD1FAE5), // Light Emerald
        onPrimaryContainer: Color(0xFF064E3B), // Dark Emerald
        
        // Secondary Colors
        secondary: Color(0xFFF59E0B), // Amber Gold
        onSecondary: Color(0xFFFFFFFF), // White
        secondaryContainer: Color(0xFFFEF3C7), // Light Amber
        onSecondaryContainer: Color(0xFF92400E), // Dark Amber
        
        // Surface Colors
        surface: Color(0xFFFFFFFF), // Pure White
        onSurface: Color(0xFF1F2937), // Rich Black
        surfaceContainerHighest: Color(0xFFF8FAFC), // Soft White
        onSurfaceVariant: Color(0xFF6B7280), // Rich Black
        
        // Error Colors
        error: Color(0xFFDC2626), // Crimson Red
        onError: Color(0xFFFFFFFF), // White
        errorContainer: Color(0xFFFEE2E2), // Light Red
        onErrorContainer: Color(0xFF991B1B), // Dark Red
        
        // Other Colors
        outline: Color(0xFFE2E8F0), // Subtle Border
        shadow: Color(0xFF0F0F23), // Midnight Shadow
        inverseSurface: Color(0xFF0F0F23), // Midnight Black
        onInverseSurface: Color(0xFFFFFFFF), // White
        inversePrimary: Color(0xFF6EE7B7), // Light Emerald
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF10B981),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF10B981),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      
      // Card Theme
      // cardTheme:  CardTheme(
      //   color: Color(0xFFFFFFFF),
      //   elevation: 8,
      //   shadowColor: Color(0x1A0F0F23),
      //   surfaceTintColor: Colors.transparent,
      // ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 8,
          shadowColor: const Color(0x4D10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2937),
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1F2937),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1F2937),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
  
  // 🌙 DARK THEME - Midnight Professional
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        // Primary Colors
        primary: Color(0xFF6EE7B7), // Light Emerald
        onPrimary: Color(0xFF064E3B), // Dark Emerald
        primaryContainer: Color(0xFF047857), // Medium Emerald
        onPrimaryContainer: Color(0xFFD1FAE5), // Very Light Emerald
        
        // Secondary Colors
        secondary: Color(0xFFFBBF24), // Light Amber
        onSecondary: Color(0xFF92400E), // Dark Amber
        secondaryContainer: Color(0xFFD97706), // Medium Amber
        onSecondaryContainer: Color(0xFFFEF3C7), // Very Light Amber
        
        // Surface Colors
        surface: Color(0xFF1F2937), // Dark Gray
        onSurface: Color(0xFFF9FAFB), // Almost White
        surfaceVariant: Color(0xFF374151), // Medium Dark Gray
        onSurfaceVariant: Color(0xFFD1D5DB), // Light Gray
        
        // Background Colors
        background: Color(0xFF0F0F23), // Midnight Black
        onBackground: Color(0xFFF9FAFB), // Almost White
        
        // Error Colors
        error: Color(0xFFF87171), // Light Red
        onError: Color(0xFF7F1D1D), // Dark Red
        errorContainer: Color(0xFFDC2626), // Medium Red
        onErrorContainer: Color(0xFFFEE2E2), // Very Light Red
        
        // Other Colors
        outline: Color(0xFF4B5563), // Medium Gray
        shadow: Color(0xFF000000), // Pure Black
        inverseSurface: Color(0xFFF9FAFB), // Almost White
        onInverseSurface: Color(0xFF1F2937), // Dark Gray
        inversePrimary: Color(0xFF10B981), // Emerald Green
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F23),
        foregroundColor: Color(0xFFF9FAFB),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0F0F23),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      
      // Card Theme
      // cardTheme: const CardTheme(
      //   color: Color(0xFF1F2937),
      //   elevation: 8,
      //   shadowColor: Color(0x4D000000),
      //   surfaceTintColor: Colors.transparent,
      // ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6EE7B7),
          foregroundColor: const Color(0xFF064E3B),
          elevation: 8,
          shadowColor: const Color(0x4D6EE7B7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6EE7B7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4B5563)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4B5563)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6EE7B7), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Color(0xFFF9FAFB),
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF9FAFB),
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF9FAFB),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF9FAFB),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF9FAFB),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF9FAFB),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF9FAFB),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFF9FAFB),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD1D5DB),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFF9FAFB),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFF9FAFB),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFFD1D5DB),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF9FAFB),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFD1D5DB),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}

// Custom App Colors for both themes
class AppColors {
  // 🌟 Light Theme Colors
  static const Color lightPrimary = Color(0xFF10B981); // Emerald Green
  static const Color lightSecondary = Color(0xFFF59E0B); // Amber Gold
  static const Color lightBackground = Color(0xFFF8FAFC); // Soft White
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightText = Color(0xFF1F2937); // Rich Black
  static const Color lightTextSecondary = Color(0xFF6B7280); // Cool Gray
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle Border
  static const Color lightShadow = Color(0x1A0F0F23); // Midnight Shadow
  
  // 🌙 Dark Theme Colors
  static const Color darkPrimary = Color(0xFF6EE7B7); // Light Emerald
  static const Color darkSecondary = Color(0xFFFBBF24); // Light Amber
  static const Color darkBackground = Color(0xFF0F0F23); // Midnight Black
  static const Color darkSurface = Color(0xFF1F2937); // Dark Gray
  static const Color darkText = Color(0xFFF9FAFB); // Almost White
  static const Color darkTextSecondary = Color(0xFFD1D5DB); // Light Gray
  static const Color darkBorder = Color(0xFF4B5563); // Medium Gray
  static const Color darkShadow = Color(0x4D000000); // Black Shadow
  
  // 🎨 Common Colors (work in both themes)
  static const Color success = Color(0xFF059669); // Deep Green
  static const Color warning = Color(0xFFD97706); // Orange
  static const Color error = Color(0xFFDC2626); // Crimson Red
  static const Color info = Color(0xFF2563EB); // Royal Blue
}
