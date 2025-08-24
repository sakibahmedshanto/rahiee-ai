// ignore_for_file: file_names, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/user_model.dart';

class GetUserDataController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Object?>>> getUserData(String uId) async {
    final QuerySnapshot userData =
        await _firestore.collection('users').where('uId', isEqualTo: uId).get();
    return userData.docs;
  }
  
   Future<UserModel?> getUserModel(String uId) async {
    try {
      // Fetch user data from Firestore based on uId
      final QuerySnapshot userData =
          await _firestore.collection('users').where('uId', isEqualTo: uId).limit(1).get();
      
      if (userData.docs.isNotEmpty) {
        // Convert the first document to a UserModel
        var userDoc = userData.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromMap(userDoc);
      } else {
        return null; // Return null if no user found with the given uId
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null; // Return null in case of an error
    }
  }
}
