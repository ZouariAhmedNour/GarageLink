import 'package:garagelink/auth/login.dart';
import 'package:garagelink/auth/reset_password.dart';
import 'package:garagelink/auth/signup.dart';
import 'package:garagelink/complete_profile.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/dashboard/screens/dash_board_screen.dart';
import 'package:garagelink/mecanicien/devis/creation_devis.dart';
import 'package:garagelink/mecanicien/devis/devis_preview_page.dart';
import 'package:garagelink/mecanicien/edit_localisation.dart';
import 'package:garagelink/mecanicien/mecaHome.dart';
import 'package:garagelink/mecanicien/meca_services/meca_services.dart';
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
    GetPage(name: AppRoutes.dashboard, page: () =>  DashBoardScreen()),
    GetPage(name: AppRoutes.mecaServices, page: () =>  MecaServicesPage()),
    GetPage(name: AppRoutes.editLocalisation, page: () =>  EditLocalisation()),
    GetPage(name: AppRoutes.creation_devis, page: () =>  CreationDevisPage()),
    GetPage(name: AppRoutes.devis_preview_page, page: () =>  DevisPreviewPage()),
  ];
}
