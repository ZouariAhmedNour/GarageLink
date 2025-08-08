import 'package:garagelink/auth/login.dart';
import 'package:garagelink/auth/reset_password.dart';
import 'package:garagelink/auth/signup.dart';
import 'package:garagelink/complete_profile.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/mecanicien/mecaHome.dart';
import 'package:garagelink/splash_screen.dart';
import 'package:get/get.dart';

class GenerateRoutes {
  static final getPages = [
    GetPage(name: AppRoutes.login, page: () =>  LoginPage()),
    GetPage(name: AppRoutes.signup, page: () => SignUpPage()),
    GetPage(name: AppRoutes.mecaHome, page: () => MecaHomePage()),
    //GetPage(name: AppRoutes.adminHome, page: () => AdminHomePage()),
    //GetPage(name: AppRoutes.userHome, page: () => UserHomePage()),
    GetPage(name: AppRoutes.completeProfile, page: () => CompleteProfilePage()),
    GetPage(name: AppRoutes.resetPassword, page: () => ResetPasswordPage()),
    GetPage(name: AppRoutes.splashScreen, page: () =>  SplashScreen()),
  ];
}
