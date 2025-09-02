// ignore_for_file: file_names, unused_field

import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';

class GetUserDataController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;

  Future<List<Map<String, dynamic>>> getUserData(String uId) async {
    try {
      final userData = await _supabaseService.select(
        'my_users',
        eq: 'id',
        eqValue: uId,
      );
      return userData;
    } catch (e) {
      print('Error getting user data: $e');
      return [];
    }
  }
  
  Future<UserModel?> getUserModel(String uId) async {
    try {
      print('DEBUG: Getting user model for uId: $uId');
      
      // Fetch user data from Supabase based on uId
      final userData = await _supabaseService.selectSingle(
        'my_users',
        eq: 'id',
        eqValue: uId,
      );
      
      if (userData != null) {
        print('DEBUG: Found user data: ${userData['full_name']}');
        return UserModel.fromMap(userData);
      } else {
        print('DEBUG: No user found with uId: $uId');
        return null;
      }
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }

  Future<bool> createUserModel(UserModel userModel) async {
    try {
      print('DEBUG: Creating user model for: ${userModel.fullName}');
      print('DEBUG: User ID: ${userModel.uId}');
      print('DEBUG: Employee ID: ${userModel.employeeId}');
      print('DEBUG: Email: ${userModel.email}');
      
      final userMap = userModel.toMap();
      print('DEBUG: User data to insert: $userMap');
      
      await _supabaseService.insert('my_users', userMap);
      
      print('DEBUG: Successfully created user model');
      return true;
    } catch (e) {
      print('ERROR: Failed to create user model: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> updateUserModel(UserModel userModel) async {
    try {
      print('DEBUG: Updating user model for: ${userModel.fullName}');
      
      await _supabaseService.update(
        'my_users',
        userModel.toMap(),
        eq: 'id',
        eqValue: userModel.uId,
      );
      
      print('DEBUG: Successfully updated user model');
      return true;
    } catch (e) {
      print('Error updating user model: $e');
      return false;
    }
  }

  Future<List<UserModel>> getAllActiveUsers() async {
    try {
      print('DEBUG: Getting all active users');
      
      final usersData = await _supabaseService.select(
        'my_users',
        eq: 'is_active',
        eqValue: true,
        orderBy: 'full_name',
      );
      
      final List<UserModel> users = [];
      for (final userData in usersData) {
        try {
          final user = UserModel.fromMap(userData);
          users.add(user);
        } catch (e) {
          print('Error parsing user: $e');
        }
      }
      
      print('DEBUG: Successfully loaded ${users.length} active users');
      return users;
    } catch (e) {
      print('Error getting all active users: $e');
      return [];
    }
  }
}
