// ignore_for_file: file_names, unused_local_variable, unused_field, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/landing_screen/landing_screen.dart';
import 'get_device_token_controller.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInController extends GetxController {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithGoogle() async {
    final GetDeviceTokenController getDeviceTokenController =
        Get.put(GetDeviceTokenController());
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        EasyLoading.show(status: "Please wait..");
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        final User? user = userCredential.user;

        if (user != null) {
          UserModel userModel = UserModel(
            uId: user.uid,
            employeeId: 'EMP-${user.uid.substring(0, 8).toUpperCase()}', // Generate employee ID
            username: user.displayName.toString(),
            email: user.email.toString(),
            phone: user.phoneNumber?.toString() ?? '',
            fullName: user.displayName.toString(),
            department: 'General', // Default department
            position: 'Employee', // Default position
            userRole: 'employee', // Default role
            userImg: user.photoURL?.toString(),
            userDeviceToken: getDeviceTokenController.deviceToken.toString(),
            isActive: true,
            createdOn: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
          EasyLoading.dismiss();
         Get.offAll(() => LandingScreen(userModel: userModel,));
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      print("error $e");
    }
  }
}
