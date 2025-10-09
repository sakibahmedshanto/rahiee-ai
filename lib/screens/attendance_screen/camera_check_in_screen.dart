import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/camera_check_in_controller.dart';
import '../../utils/app_constant.dart';

/// Screen for capturing check-in/check-out photo with uniform verification
class CameraCheckInScreen extends StatelessWidget {
  final String scheduleId;
  final String scheduleTitle;
  final VoidCallback onCheckInComplete;

  const CameraCheckInScreen({
    super.key,
    required this.scheduleId,
    required this.scheduleTitle,
    required this.onCheckInComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is checkout mode (attendanceId in arguments)
    final isCheckout = Get.arguments?['attendanceId'] != null;
    final attendanceId = Get.arguments?['attendanceId'] as String?;
    
    final controller = Get.put(
      CameraCheckInController(
        scheduleId: isCheckout ? null : scheduleId,
        attendanceId: attendanceId,
        onComplete: onCheckInComplete,
        isCheckout: isCheckout,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.modeTitle),
        backgroundColor: isCheckout ? AppConstant.errorColor : AppConstant.primaryColor,
      ),
      body: Obx(() {
        if (controller.isVerifying.value) {
          return _buildVerifyingState();
        }

        if (controller.capturedImage.value != null) {
          return _buildPreviewState(controller);
        }

        return _buildCaptureState(controller);
      }),
    );
  }

  /// Initial state - Capture photo
  Widget _buildCaptureState(CameraCheckInController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              size: 120,
              color: AppConstant.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 32),
            Text(
              'Check In for',
              style: TextStyle(
                fontSize: 18,
                color: AppConstant.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.scheduleTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstant.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstant.infoColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.checkroom_rounded,
                    color: AppConstant.infoColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please ensure you are wearing your uniform',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstant.infoColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => controller.capturePhoto(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Take Photo',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => controller.capturePhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  /// Preview state - Show captured photo
  Widget _buildPreviewState(CameraCheckInController controller) {
    final image = controller.capturedImage.value!;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Image.file(
              image,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.retakePhoto,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppConstant.textSecondary),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: controller.verifyAndCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstant.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        'Verify & Check In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Verifying state - Show AI processing
  Widget _buildVerifyingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstant.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstant.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Verifying uniform...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI is analyzing your photo',
              style: TextStyle(
                fontSize: 16,
                color: AppConstant.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
