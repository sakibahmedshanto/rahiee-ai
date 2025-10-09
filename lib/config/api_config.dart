/// API Configuration
/// 
/// This file contains all API endpoints and configuration constants
class ApiConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I';
  
  // Edge Function URLs
  static const String verifyUniformUrl = '$supabaseUrl/functions/v1/verify-uniform';
  
  // Storage Configuration
  static const String attendancePhotosBucket = 'attendance-photos';
  
  // API Timeouts
  static const int defaultTimeoutSeconds = 30;
  static const int uniformVerificationTimeoutSeconds = 15;
  
  // Photo Upload Constraints
  static const int maxPhotoSizeKB = 5120; // 5 MB
  static const List<String> allowedPhotoFormats = ['jpg', 'jpeg', 'png'];
  
  // Uniform Verification Thresholds
  static const double uniformConfidenceThreshold = 50.0; // Confidence above this = uniform detected
  static const int maxVerificationAttempts = 5;
}




