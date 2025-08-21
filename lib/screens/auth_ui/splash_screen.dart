// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace
import 'dart:async';
import '../../../controllers/auth_controller/get_user_data_controller.dart';
import '../../utils/app_constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      loggdin(context);
    });
  }

  Future<void> loggdin(BuildContext context) async {
    if (user != null) {
      final GetUserDataController getUserDataController =
          Get.put(GetUserDataController());
      var userData = await getUserDataController.getUserData(user!.uid);
      UserModel? userModel = await getUserDataController.getUserModel(user!.uid);

      if (userData[0]['isAdmin'] == true) {
        Get.offAll(() => AdminScreen());
      } else {
        Get.offAll(() => LandingScreen(userModel: userModel!,));
      }
    } else {
      Get.to(() => ViewserSlider());
    }
  }

  @override
  Widget build(BuildContext context) {
    //final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppConstant.appScendoryColor,
      appBar: AppBar(
        backgroundColor: AppConstant.appScendoryColor,
        elevation: 0,
      ),
      body: Column(

        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 70,),
            Container(
              width: Get.width/1.2,
              alignment: Alignment.center,
              child: Lottie.asset('assets/images/splash_animation.json'),
            ),
            Text("Loading...", style: TextStyle(
                  color: AppConstant.appTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900)),
            SizedBox(height: Get.height/3.5,),
          Container(
            width: Get.width,
            alignment: Alignment.center,
            child: Text(
              AppConstant.appPoweredBy,
              style: TextStyle(
                  color: AppConstant.appTextColor,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
