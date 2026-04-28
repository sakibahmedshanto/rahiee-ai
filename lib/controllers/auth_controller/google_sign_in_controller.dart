// ignore_for_file: file_names, unused_local_variable, unused_field, avoid_print

import 'package:flutter/widgets.dart';
import '../../screens/landing_screen/landing_screen.dart';
import '../../models/user_model.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/supabase_service.dart';
import '../../services/fcm_service.dart';
import 'get_user_data_controller.dart';

class GoogleSignInController extends GetxController {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);
  final SupabaseService _supabaseService = SupabaseService.to;
  final GetUserDataController _getUserDataController = Get.put(GetUserDataController());
  final FCMService _fcmService = Get.find<FCMService>();

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        EasyLoading.show(status: "Please wait..");
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        try {
          // Use Supabase Google OAuth
          final response = await _supabaseService.signInWithGoogle(
            idToken: googleSignInAuthentication.idToken!,
            accessToken: googleSignInAuthentication.accessToken!,
          );

          if (response?.user != null) {
            final user = response!.user!;
            final userEmail = user.email!;
            final userName = user.userMetadata?['full_name'] ?? 
                            user.userMetadata?['name'] ?? 
                            googleSignInAccount.displayName ?? '';
            
            // Check if user profile exists in our users table
            UserModel? existingUser = await _getUserDataController.getUserModel(user.id);
            
            if (existingUser == null) {
              // Create new user profile in Supabase database
              UserModel userModel = UserModel(
                uId: user.id,
                employeeId: 'EMP-${user.id.substring(0, 8).toUpperCase()}',
                username: userName,
                email: userEmail,
                phone: '',
                fullName: userName,
                department: 'General',
                position: 'Employee',
                userRole: 'employee',
                userImg: user.userMetadata?['avatar_url'] ?? googleSignInAccount.photoUrl,
                userDeviceToken: '', // Device token removed - can be added later if needed
                isActive: true,
                createdOn: DateTime.now(),
              );

              bool userCreated = await _getUserDataController.createUserModel(userModel);
              
              // Save device token for push notifications
              if (userCreated) {
                try {
                  await _fcmService.saveDeviceTokenForUser(user.id);
                } catch (e) {
                  print('Failed to save device token: $e');
                }
              }
              
              EasyLoading.dismiss();
              
              if (userCreated) {
                print('✅ User data successfully stored in Supabase database');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAll(() => LandingScreen(userModel: userModel));
                });
                return true;
              } else {
                // Let UI handle error display
                print('Failed to create user profile. Please try again.');
                return false;
              }
            } else {
              // Update existing user's profile image if changed
              UserModel updatedUser = existingUser.copyWith(
                userImg: user.userMetadata?['avatar_url'] ?? existingUser.userImg,
              );
              
              // Save device token for push notifications
              try {
                await _fcmService.saveDeviceTokenForUser(user.id);
              } catch (e) {
                print('Failed to save device token: $e');
              }
              
              // Only update if profile image actually changed
              if (updatedUser.userImg != existingUser.userImg) {
                bool userUpdated = await _getUserDataController.updateUserModel(updatedUser);
                EasyLoading.dismiss();
                
                if (userUpdated) {
                  print('✅ User profile updated in Supabase database');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Get.offAll(() => LandingScreen(userModel: updatedUser));
                  });
                  return true;
                } else {
                  print('⚠️ Failed to update user profile, proceeding anyway');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Get.offAll(() => LandingScreen(userModel: existingUser));
                  });
                  return true;
                }
              } else {
                EasyLoading.dismiss();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAll(() => LandingScreen(userModel: existingUser));
                });
                return true;
              }
            }
          } else {
            EasyLoading.dismiss();
            print('Failed to authenticate with Google');
            return false;
          }
        } catch (e) {
          EasyLoading.dismiss();
          print('Google Sign-in error: $e');
          // Let UI handle error display
          return false;
        }
      } else {
        // User cancelled the sign-in
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      print("Google Sign-in error: $e");
      // Let UI handle error display
      return false;
    }
  }
}
