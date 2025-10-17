// ignore_for_file: file_names

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller/get_user_data_controller.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class FCMService extends GetxService {
  static FCMService get to => Get.find();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GetUserDataController _getUserDataController = GetUserDataController();
  
  String? _deviceToken;
  
  String? get deviceToken => _deviceToken;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeFCM();
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> initializeFCM() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
        
        // Get the device token
        await _getDeviceToken();
        
        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((String token) {
          debugPrint('FCM Token refreshed: $token');
          _deviceToken = token;
          _updateDeviceTokenInDatabase(token);
        });
        
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission for notifications');
        await _getDeviceToken();
      } else {
        debugPrint('User declined or has not accepted permission for notifications');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Get the current device token
  Future<String?> _getDeviceToken() async {
    try {
      _deviceToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Device Token: $_deviceToken');
      return _deviceToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save device token to database for the current user
  Future<bool> saveDeviceTokenForUser(String userId) async {
    try {
      if (_deviceToken == null) {
        await _getDeviceToken();
      }
      
      if (_deviceToken == null) {
        debugPrint('No device token available to save');
        return false;
      }

      // Get current user model
      UserModel? userModel = await _getUserDataController.getUserModel(userId);
      if (userModel == null) {
        debugPrint('User not found: $userId');
        return false;
      }

      // Update user model with device token
      UserModel updatedUserModel = userModel.copyWith(
        userDeviceToken: _deviceToken,
      );

      // Save to database
      bool success = await _getUserDataController.updateUserModel(updatedUserModel);
      
      if (success) {
        debugPrint('Device token saved successfully for user: $userId');
      } else {
        debugPrint('Failed to save device token for user: $userId');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error saving device token: $e');
      return false;
    }
  }

  /// Update device token in database (called when token refreshes)
  Future<void> _updateDeviceTokenInDatabase(String newToken) async {
    try {
      // Get current user from Supabase auth
      final supabase = Get.find<SupabaseService>();
      final user = supabase.client?.auth.currentUser;
      
      if (user != null) {
        await saveDeviceTokenForUser(user.id);
      }
    } catch (e) {
      debugPrint('Error updating device token in database: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    
    if (message.notification != null) {
      debugPrint('Message notification: ${message.notification?.title}');
      debugPrint('Message notification body: ${message.notification?.body}');
      
      // Show in-app notification or handle the message
      _showInAppNotification(
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
      );
    }
  }

  /// Handle notification tap when app is in background
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    
    // Navigate to relevant screen based on message data
    _handleNotificationNavigation(message.data);
  }

  /// Show in-app notification
  void _showInAppNotification(String title, String body) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.primaryColor,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Implement navigation logic based on notification data
    // For example:
    // if (data['type'] == 'attendance') {
    //   Get.toNamed('/attendance');
    // } else if (data['type'] == 'schedule') {
    //   Get.toNamed('/schedule');
    // }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get current notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  
  // Handle background message processing here
  // Note: This function must be top-level and cannot be a class method
}
