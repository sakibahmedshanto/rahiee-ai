import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'supabase_service.dart';

/// Service to handle uniform verification using Supabase Edge Function
class UniformVerificationService {
  static UniformVerificationService get to => Get.find();
  final SupabaseService _supabaseService = SupabaseService.to;

  // Edge Function URL from config
  static const String _edgeFunctionUrl = 
      'https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/verify-uniform';

  /// Verify uniform in image using Edge Function
  /// 
  /// Returns:
  /// ```dart
  /// {
  ///   'success': true/false,
  ///   'wearing_uniform': true/false,
  ///   'confidence': 0-100,
  ///   'message': 'User-friendly message',
  ///   'suggestions': ['Tip 1', 'Tip 2'], // Optional
  ///   'detection_data': {...} // Raw AI results
  /// }
  /// ```
  Future<Map<String, dynamic>> verifyUniform({
    required File imageFile,
    required String userId,
    String? scheduleId,
    int timeoutSeconds = 15,
  }) async {
    try {
      print('📸 Starting uniform verification...');
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      print('📦 Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      
      // Get auth token
      final session = _supabaseService.client?.auth.currentSession;
      if (session == null) {
        return {
          'success': false,
          'wearing_uniform': false,
          'confidence': 0,
          'message': 'Authentication required. Please login.',
        };
      }

      // Call Edge Function
      print('🚀 Calling Edge Function...');
      final response = await http
          .post(
            Uri.parse(_edgeFunctionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({
              'image_base64': base64Image,
              'user_id': userId,
              'schedule_id': scheduleId,
            }),
          )
          .timeout(
            Duration(seconds: timeoutSeconds),
            onTimeout: () {
              throw Exception('Request timeout. Please try again.');
            },
          );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Full result object: $result');
        print('✅ Verification complete: ${result['wearing_uniform']} (${result['confidence']}%)');
        print('✅ Success flag: ${result['success']}');
        print('✅ Message: ${result['message']}');
        return result;
      } else {
        final errorBody = response.body;
        print('❌ Edge Function error: $errorBody');
        
        // Try to parse error message
        try {
          final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
          return {
            'success': false,
            'wearing_uniform': false,
            'confidence': 0,
            'message': errorJson['message'] ?? 'Verification failed',
          };
        } catch (e) {
          return {
            'success': false,
            'wearing_uniform': false,
            'confidence': 0,
            'message': 'Server error. Please try again.',
          };
        }
      }
      
    } on SocketException {
      return {
        'success': false,
        'wearing_uniform': false,
        'confidence': 0,
        'message': 'No internet connection. Please check your network.',
      };
    } catch (e) {
      print('❌ Verification error: $e');
      return {
        'success': false,
        'wearing_uniform': false,
        'confidence': 0,
        'message': 'Verification failed: ${e.toString()}',
      };
    }
  }

  /// Test Edge Function connectivity
  Future<bool> testConnection() async {
    try {
      final session = _supabaseService.client?.auth.currentSession;
      if (session == null) return false;

      final response = await http
          .get(
            Uri.parse(_edgeFunctionUrl),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
            },
          )
          .timeout(Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 405; // 405 = Method not allowed (GET on POST endpoint)
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
