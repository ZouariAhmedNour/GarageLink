import 'package:garagelink/auth/login.dart';
import 'package:garagelink/auth/reset_password.dart';
import 'package:garagelink/auth/signup.dart';
import 'package:garagelink/carnet%20Entretien/entretien_screen.dart';
import 'package:garagelink/complete_profile.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/mecanicien/Facture/facture_detail_page.dart';
import 'package:garagelink/mecanicien/Facture/facture_screen.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/add_client.dart';
import 'package:garagelink/vehicules/add_veh.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/client_dash.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/edit_client.dart';
import 'package:garagelink/vehicules/vehicule_info.dart';
import 'package:garagelink/mecanicien/dashboard/screens/dash_board_screen.dart';
import 'package:garagelink/mecanicien/devis/creation_devis.dart';
import 'package:garagelink/mecanicien/devis/devis_preview_page.dart';
import 'package:garagelink/mecanicien/devis/historique_devis.dart';
import 'package:garagelink/mecanicien/edit_localisation.dart';
import 'package:garagelink/mecanicien/gestion%20mec/add_mec_screen.dart';
import 'package:garagelink/mecanicien/gestion%20mec/mec_list_screen.dart';
import 'package:garagelink/mecanicien/mecaHome.dart';
import 'package:garagelink/mecanicien/meca_services/add_edit_service_screen.dart';
import 'package:garagelink/mecanicien/meca_services/meca_services.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';
import 'package:garagelink/mecanicien/work%20order/create_order_screen.dart';
import 'package:garagelink/mecanicien/work%20order/notif_screen.dart';
import 'package:garagelink/mecanicien/work%20order/rapport_screen.dart';
import 'package:garagelink/mecanicien/work%20order/work_order_page.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/order.dart';
import 'package:garagelink/splash_screen.dart';
import 'package:get/get.dart';

class GenerateRoutes {
  static final getPages = [
    GetPage(name: AppRoutes.login, page: () => LoginPage()),
    GetPage(name: AppRoutes.signup, page: () => SignUpPage()),
    GetPage(name: AppRoutes.mecaHome, page: () => MecaHomePage()),
    //GetPage(name: AppRoutes.adminHome, page: () => AdminHomePage()),
    //GetPage(name: AppRoutes.userHome, page: () => UserHomePage()),
    GetPage(name: AppRoutes.completeProfile, page: () => CompleteProfilePage()),
    GetPage(name: AppRoutes.resetPassword, page: () => ResetPasswordPage()),
    GetPage(name: AppRoutes.splashScreen, page: () => SplashScreen()),
    GetPage(name: AppRoutes.dashboard, page: () => DashBoardScreen()),
    GetPage(name: AppRoutes.mecaServices, page: () => MecaServicesPage()),
    GetPage(name: AppRoutes.editLocalisation, page: () => EditLocalisation()),
    GetPage(name: AppRoutes.creationDevis, page: () => CreationDevisPage()),
    GetPage(name: AppRoutes.devisPreviewPage, page: () => DevisPreviewPage()),
    GetPage(
      name: AppRoutes.historiqueDevis,
      page: () => HistoriqueDevisPage(),
    ),
    GetPage(name: AppRoutes.workOrderPage, page: () => WorkOrderPage()),
    GetPage(name: AppRoutes.notifScreen, page: () => NotifScreen()),
    GetPage(
      name: AppRoutes.rapportScreen,
      page: () {
        final order = Get.arguments as WorkOrder;
        return RapportScreen(order: order);
      },
    ),
    GetPage(name: AppRoutes.createOrderScreen, page: () => CreateOrderScreen()),
    GetPage(
      name: AppRoutes.addEditServiceScreen,
      page: () => AddEditServiceScreen(),
    ),
    GetPage(name: AppRoutes.stockDashboard, page: () => StockDashboard()),
  GetPage(name: AppRoutes.factureScreen, page: () => const FactureScreen()),
  GetPage(
  name: AppRoutes.factureDetailPage,
  page: () {
    final facture = Get.arguments as Facture; // Récupération de l'argument
    return FactureDetailPage(facture: facture);
  },
),
      
    GetPage(name: AppRoutes.mecListScreen, page: () => MecListScreen()),
    GetPage(name: AppRoutes.addMecScreen, page: () => AddMecScreen()),
    GetPage(name: AppRoutes.clientDash, page: () => ClientDash()),
    GetPage(name: AppRoutes.addClientScreen, page: () => AddClientScreen()),
    GetPage(
      name: AppRoutes.addVehiculeScreen,
      page: () {
        final clientId = Get.arguments as String;
        return AddVehScreen(clientId: clientId);
      },
    ),
   GetPage(
  name: AppRoutes.vehiculeInfoScreen,
  page: () => VehiculeInfoScreen(vehiculeId: Get.arguments as String),
),
    GetPage(
  name: AppRoutes.editClientScreen,
  page: () {
    final client = Get.arguments as Client;
    return EditClientScreen(client: client);
  },
),
    GetPage(name: AppRoutes.entretienScreen, page: () {
      final vehiculeId = Get.arguments as String;
      return EntretienScreen(vehiculeId: vehiculeId);
    }),
  ];
}
