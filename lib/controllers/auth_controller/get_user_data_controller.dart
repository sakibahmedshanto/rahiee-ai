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
      // Fetch user data from Supabase based on uId
      final userData = await _supabaseService.selectSingle(
        'my_users',
        eq: 'id',
        eqValue: uId,
      );
      
      if (userData != null) {
        return UserModel.fromMap(userData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }

  Future<bool> createUserModel(UserModel userModel) async {
    try {
      final userMap = userModel.toMap();
      await _supabaseService.insert('my_users', userMap);
      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      if (e.toString().contains('column') && e.toString().contains('does not exist')) {
        // Try creating with minimal data compatible with old schema
        return await _createUserWithMinimalData(userModel);
      }
      return false;
    }
  }

  Future<bool> _createUserWithMinimalData(UserModel userModel) async {
    try {
      // Create minimal user data that should work with both old and new schema
      final minimalUserMap = {
        'id': userModel.uId,
        'email': userModel.email,
        'full_name': userModel.fullName,
      };

      // Add optional fields that might exist in the old schema
      if (userModel.phone != null && userModel.phone!.isNotEmpty) {
        minimalUserMap['phone_number'] = userModel.phone!; // Old schema uses phone_number
      }
      
      if (userModel.department.isNotEmpty) {
        minimalUserMap['department'] = userModel.department;
      }
      
      if (userModel.position.isNotEmpty) {
        minimalUserMap['position'] = userModel.position;
      }

      if (userModel.employeeId.isNotEmpty) {
        minimalUserMap['employee_id'] = userModel.employeeId;
      }

      await _supabaseService.insert('my_users', minimalUserMap);
      return true;
    } catch (e) {
      print('Error creating user profile with minimal data: $e');
      return false;
    }
  }

  Future<bool> updateUserModel(UserModel userModel) async {
    try {
      await _supabaseService.update(
        'my_users',
        userModel.toMap(),
        eq: 'id',
        eqValue: userModel.uId,
      );
      
      return true;
    } catch (e) {
      print('Error updating user model: $e');
      return false;
    }
  }

  Future<List<UserModel>> getAllActiveUsers() async {
    try {
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
