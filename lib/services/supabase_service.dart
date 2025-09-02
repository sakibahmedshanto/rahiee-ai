// ignore_for_file: file_names
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class SupabaseService extends GetxService {
  static SupabaseService get to => Get.find();
  
  // Replace these with your Supabase project credentials
  // Get them from https://YOUR_SUPABASE_PROJECT_REF.supabase.com -> Project Settings -> API
  static const String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I';
  
  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  // Auth methods
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signUpWithEmail(String email, String password, {
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
  
  // Google Sign In (note: requires Google OAuth setup in Supabase dashboard)
  Future<AuthResponse> signInWithGoogle({String? idToken, String? accessToken}) async {
    try {
      if (idToken != null && accessToken != null) {
        // Sign in with ID token and access token from Google Sign-In
        return await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } else {
        // For web or OAuth redirect - this returns bool, not AuthResponse
        // For mobile apps, you should always provide tokens
        throw Exception('Google OAuth tokens are required for mobile authentication');
      }
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }
  
  // Database helper methods
  Future<List<Map<String, dynamic>>> select(String table, {
    String? select,
    String? eq,
    dynamic eqValue,
    String? gt,
    dynamic gtValue,
    String? lt,
    dynamic ltValue,
    String? gte,
    dynamic gteValue,
    String? lte,
    dynamic lteValue,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    dynamic query = client.from(table).select(select ?? '*');
    
    if (eq != null && eqValue != null) {
      query = query.eq(eq, eqValue);
    }
    if (gt != null && gtValue != null) {
      query = query.gt(gt, gtValue);
    }
    if (lt != null && ltValue != null) {
      query = query.lt(lt, ltValue);
    }
    if (gte != null && gteValue != null) {
      query = query.gte(gte, gteValue);
    }
    if (lte != null && lteValue != null) {
      query = query.lte(lte, lteValue);
    }
    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<Map<String, dynamic>?> selectSingle(String table, {
    String? select,
    String? eq,
    dynamic eqValue,
  }) async {
    try {
      dynamic query = client.from(table).select(select ?? '*');
      
      if (eq != null && eqValue != null) {
        query = query.eq(eq, eqValue);
      }
      
      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Select single query failed: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> insert(String table, Map<String, dynamic> data) async {
    return await client.from(table).insert(data).select();
  }
  
  Future<List<Map<String, dynamic>>> update(String table, Map<String, dynamic> data, {
    String? eq,
    dynamic eqValue,
  }) async {
    try {
      dynamic query = client.from(table).update(data);
      
      if (eq != null && eqValue != null) {
        query = query.eq(eq, eqValue);
      }
      
      final response = await query.select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Update query failed: $e');
    }
  }
  
  Future<void> delete(String table, {
    String? eq,
    dynamic eqValue,
  }) async {
    try {
      dynamic query = client.from(table).delete();
      
      if (eq != null && eqValue != null) {
        query = query.eq(eq, eqValue);
      }
      
      await query;
    } catch (e) {
      throw Exception('Delete query failed: $e');
    }
  }

  // Helper method to check if a user exists in the database
  Future<bool> userExistsInDatabase(String userId) async {
    try {
      final response = await client
          .from('my_users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Test method to verify database connection and user operations
  Future<bool> testUserOperations() async {
    try {
      print('🧪 Testing Supabase user operations...');
      
      // Test 1: Try to select from my_users table
      final testSelect = await client.from('my_users').select('count').count();
      print('✅ Database connection successful - User count: ${testSelect.count}');
      
      // Test 2: Check if current user exists
      if (currentUser != null) {
        bool userExists = await userExistsInDatabase(currentUser!.id);
        print('✅ Current user exists in database: $userExists');
      }
      
      print('🎉 All user operation tests passed!');
      return true;
    } catch (e) {
      print('❌ User operation test failed: $e');
      return false;
    }
  }
}
