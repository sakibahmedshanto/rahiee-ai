import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/uniform_verification_service.dart';
import '../services/photo_storage_service.dart';
import '../services/attendance_management_service.dart';
import '../services/location_permission_service.dart';
import '../services/supabase_service.dart';
import '../utils/app_constant.dart';

class CameraCheckInController extends GetxController {
  final String? scheduleId;  // Nullable for checkout mode
  final String? attendanceId; // For checkout mode
  final VoidCallback onComplete;
  final bool isCheckout; // Mode flag

  CameraCheckInController({
    this.scheduleId,
    this.attendanceId,
    required this.onComplete,
    this.isCheckout = false,
  });

  final UniformVerificationService _verificationService = UniformVerificationService.to;
  final PhotoStorageService _photoService = PhotoStorageService.to;
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final LocationPermissionService _locationService = LocationPermissionService.to;
  final SupabaseService _supabaseService = SupabaseService.to;

  final ImagePicker _picker = ImagePicker();

  // Observable state
  final capturedImage = Rxn<File>();
  final isVerifying = false.obs;
  final verificationAttempts = 0.obs;

  String get scheduleTitle => Get.arguments?['scheduleTitle'] ?? 'Schedule';
  String get userId => _supabaseService.client?.auth.currentUser?.id ?? '';
  String get modeTitle => isCheckout ? 'Check Out Verification' : 'Check In Verification';

  /// Capture photo from camera or gallery
  Future<void> capturePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Compress to reduce file size
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.front, // Front camera for selfie
      );

      if (photo != null) {
        capturedImage.value = File(photo.path);
        print('📸 Photo captured: ${photo.path}');
      }
    } catch (e) {
      print('❌ Camera error: $e');
      Get.snackbar(
        'Camera Error',
        'Failed to capture photo: ${e.toString()}',
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Retake photo
  void retakePhoto() {
    capturedImage.value = null;
    verificationAttempts.value++;
  }

  /// Verify uniform and check in/out
  Future<void> verifyAndCheckIn() async {
    if (capturedImage.value == null) {
      Get.snackbar('Error', 'No photo captured');
      return;
    }

    isVerifying.value = true;

    try {
      verificationAttempts.value++;

      // Step 1: Verify uniform with AI
      print('🔍 Step 1: Verifying uniform...');
      final verificationResult = await _verificationService.verifyUniform(
        imageFile: capturedImage.value!,
        userId: userId,
        scheduleId: scheduleId ?? attendanceId,
      );

      if (!verificationResult['success']) {
        isVerifying.value = false;
        _showErrorDialog(
          title: 'Verification Failed',
          message: verificationResult['message'] ?? 'Please try again',
        );
        return;
      }

      final wearingUniform = verificationResult['wearing_uniform'] ?? false;
      final confidence = verificationResult['confidence'] ?? 0;
      final message = verificationResult['message'] ?? '';

      print('✅ Verification result: $wearingUniform ($confidence%)');

      // Step 2: If no uniform detected, ask user
      if (!wearingUniform) {
        isVerifying.value = false;
        await _showNoUniformDialog(
          message: message,
          suggestions: verificationResult['suggestions'],
          verificationData: verificationResult,
        );
        return;
      }

      // Step 3: Upload photo to storage
      print('📤 Step 2: Uploading photo...');
      final uploadResult = isCheckout
          ? await _photoService.uploadCheckOutPhoto(
              photoFile: capturedImage.value!,
              userId: userId,
              attendanceId: attendanceId!,
            )
          : await _photoService.uploadCheckInPhoto(
              photoFile: capturedImage.value!,
              userId: userId,
              scheduleId: scheduleId,
            );

      if (!uploadResult['success']) {
        isVerifying.value = false;
        _showErrorDialog(
          title: 'Upload Failed',
          message: uploadResult['message'] ?? 'Failed to upload photo',
        );
        return;
      }

      // Step 4: Get location
      print('📍 Step 3: Getting location...');
      final location = await _locationService.getCurrentLocation();

      // Step 5: Check in or check out with all data
      print('✅ Step 4: ${isCheckout ? "Completing checkout" : "Creating attendance record"}...');
      
      final result = isCheckout
          ? await _attendanceService.clockOut(
              attendanceId: attendanceId!,
              latitude: location?.latitude ?? 0.0,
              longitude: location?.longitude ?? 0.0,
              address: 'Work Location',
              photoUrl: uploadResult['public_url'],
              photoPath: uploadResult['file_path'],
            )
          : await _attendanceService.clockIn(
              scheduleId: scheduleId!,
              latitude: location?.latitude ?? 0.0,
              longitude: location?.longitude ?? 0.0,
              address: 'Work Location',
              checkInPhotoUrl: uploadResult['public_url'],
              checkInPhotoPath: uploadResult['file_path'],
              wearingUniform: wearingUniform,
              uniformConfidence: confidence.toDouble(),
              uniformDetectionData: verificationResult['detection_data'],
              verificationAttempts: verificationAttempts.value,
            );

      isVerifying.value = false;

      if (result['success'] == true) {
        Get.back(); // Close camera screen
        
        final hours = result['total_hours']?.toDouble();
        final successMessage = isCheckout
            ? 'Checked out successfully! ${hours != null ? "${hours.toStringAsFixed(2)} hours worked. " : ""}Uniform verified.'
            : 'Checked in successfully! Uniform verified.';
        
        Get.snackbar(
          '✅ Success',
          successMessage,
          backgroundColor: AppConstant.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        onComplete();
      } else {
        _showErrorDialog(
          title: isCheckout ? 'Check-Out Failed' : 'Check-In Failed',
          message: result['message'] ?? 'Please try again',
        );
      }
    } catch (e) {
      isVerifying.value = false;
      print('❌ ${isCheckout ? "Checkout" : "Check-in"} error: $e');
      _showErrorDialog(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Show dialog when no uniform detected
  Future<void> _showNoUniformDialog({
    required String message,
    List<dynamic>? suggestions,
    required Map<String, dynamic> verificationData,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppConstant.warningColor),
            const SizedBox(width: 8),
            const Text('No Uniform Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (suggestions != null && suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('• $s')),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstant.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Do you still want to continue checking in without uniform verification?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Retake Photo'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.warningColor,
            ),
            child: const Text(
              'Continue Anyway',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (result == true) {
      // User chose to continue anyway
      await _continueCheckInWithoutUniform(verificationData);
    } else {
      // User chose to retake
      retakePhoto();
    }
  }

  /// Continue check-in/out even without uniform
  Future<void> _continueCheckInWithoutUniform(
    Map<String, dynamic> verificationData,
  ) async {
    isVerifying.value = true;

    try {
      // Upload photo
      final uploadResult = isCheckout
          ? await _photoService.uploadCheckOutPhoto(
              photoFile: capturedImage.value!,
              userId: userId,
              attendanceId: attendanceId!,
            )
          : await _photoService.uploadCheckInPhoto(
              photoFile: capturedImage.value!,
              userId: userId,
              scheduleId: scheduleId,
            );

      if (!uploadResult['success']) {
        isVerifying.value = false;
        _showErrorDialog(
          title: 'Upload Failed',
          message: uploadResult['message'] ?? 'Failed to upload photo',
        );
        return;
      }

      // Get location
      final location = await _locationService.getCurrentLocation();

      // Check in or check out (uniform = false)
      final result = isCheckout
          ? await _attendanceService.clockOut(
              attendanceId: attendanceId!,
              latitude: location?.latitude ?? 0.0,
              longitude: location?.longitude ?? 0.0,
              address: 'Work Location',
              photoUrl: uploadResult['public_url'],
              photoPath: uploadResult['file_path'],
            )
          : await _attendanceService.clockIn(
              scheduleId: scheduleId!,
              latitude: location?.latitude ?? 0.0,
              longitude: location?.longitude ?? 0.0,
              address: 'Work Location',
              checkInPhotoUrl: uploadResult['public_url'],
              checkInPhotoPath: uploadResult['file_path'],
              wearingUniform: false, // No uniform
              uniformConfidence: verificationData['confidence']?.toDouble() ?? 0.0,
              uniformDetectionData: verificationData['detection_data'],
              verificationAttempts: verificationAttempts.value,
            );

      isVerifying.value = false;

      if (result['success'] == true) {
        Get.back(); // Close camera screen
        Get.snackbar(
          '⚠️ ${isCheckout ? "Checked Out" : "Checked In"}',
          '${isCheckout ? "Checked out" : "Checked in"} without uniform verification.',
          backgroundColor: AppConstant.warningColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        onComplete();
      } else {
        _showErrorDialog(
          title: isCheckout ? 'Check-Out Failed' : 'Check-In Failed',
          message: result['message'] ?? 'Please try again',
        );
      }
    } catch (e) {
      isVerifying.value = false;
      _showErrorDialog(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Show error dialog
  void _showErrorDialog({required String title, required String message}) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppConstant.errorColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    // Clean up
    capturedImage.value = null;
    super.onClose();
  }
}
