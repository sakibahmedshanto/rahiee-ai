import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'supabase_service.dart';

/// Service to handle photo uploads to Supabase Storage
class PhotoStorageService {
  static PhotoStorageService get to => Get.find();
  final SupabaseService _supabaseService = SupabaseService.to;

  static const String _bucketName = 'attendance-photos';

  /// Upload check-in photo to Supabase Storage
  /// 
  /// Stores photo at: checkin/{userId}/{timestamp}.jpg
  /// Only keeps the latest attempt photo
  Future<Map<String, dynamic>> uploadCheckInPhoto({
    required File photoFile,
    required String userId,
    String? scheduleId,
  }) async {
    try {
      print('📤 Uploading check-in photo...');

      // Delete previous temporary photos for this user
      await _cleanupTempPhotos(userId);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(photoFile.path);
      final fileName = 'checkin/$userId/$timestamp$extension';

      // Upload to Supabase Storage
      await _supabaseService.client!.storage
          .from(_bucketName)
          .upload(
            fileName,
            photoFile,
          );

      print('✅ Upload complete');

      // Get public URL
      final publicUrl = _supabaseService.client!.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      return {
        'success': true,
        'file_path': fileName,
        'public_url': publicUrl,
        'message': 'Photo uploaded successfully',
      };
    } catch (e) {
      print('❌ Upload failed: $e');
      return {
        'success': false,
        'message': 'Failed to upload photo: ${e.toString()}',
      };
    }
  }

  /// Upload check-out photo (for future use)
  Future<Map<String, dynamic>> uploadCheckOutPhoto({
    required File photoFile,
    required String userId,
    required String attendanceId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(photoFile.path);
      final fileName = 'checkout/$userId/$timestamp$extension';

      await _supabaseService.client!.storage
          .from(_bucketName)
          .upload(
            fileName,
            photoFile,
          );

      final publicUrl = _supabaseService.client!.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      return {
        'success': true,
        'file_path': fileName,
        'public_url': publicUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload photo: ${e.toString()}',
      };
    }
  }

  /// Clean up temporary photos from previous attempts
  Future<void> _cleanupTempPhotos(String userId) async {
    try {
      // List all files in user's checkin folder
      final files = await _supabaseService.client!.storage
          .from(_bucketName)
          .list(path: 'checkin/$userId');

      // Keep only the most recent file, delete the rest
      if (files.length > 1) {
        // Sort by creation time (newest first)
        files.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

        // Delete all except the newest
        for (int i = 1; i < files.length; i++) {
          final filePath = 'checkin/$userId/${files[i].name}';
          await _supabaseService.client!.storage
              .from(_bucketName)
              .remove([filePath]);
          print('🗑️ Deleted old photo: $filePath');
        }
      }
    } catch (e) {
      print('⚠️ Cleanup warning: $e');
      // Don't throw error - cleanup failure shouldn't block upload
    }
  }

  /// Delete a specific photo
  Future<bool> deletePhoto(String filePath) async {
    try {
      await _supabaseService.client!.storage
          .from(_bucketName)
          .remove([filePath]);
      return true;
    } catch (e) {
      print('❌ Delete failed: $e');
      return false;
    }
  }

  /// Get signed URL for private photo (expires in 1 hour)
  Future<String?> getSignedUrl(String filePath, {int expiresIn = 3600}) async {
    try {
      final signedUrl = await _supabaseService.client!.storage
          .from(_bucketName)
          .createSignedUrl(filePath, expiresIn);
      return signedUrl;
    } catch (e) {
      print('❌ Failed to get signed URL: $e');
      return null;
    }
  }
}
