
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:get/get.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Attendre que l'état de l'utilisateur soit connu
    Future.delayed(Duration.zero, () {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        Get.offAllNamed(AppRoutes.mecaHome);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
