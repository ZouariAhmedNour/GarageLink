// import 'package:garagelink/Clients%20Screens/clientHome.dart';
import 'package:garagelink/ClientsScreens/chercherGarage.dart';
import 'package:garagelink/ClientsScreens/clientMapScreen.dart';
import 'package:garagelink/MecanicienScreens/atelier/ajouterAtelier.dart';
import 'package:garagelink/MecanicienScreens/atelier/atelier_dash.dart';
import 'package:garagelink/MecanicienScreens/atelier/modifierAtelier.dart';
// import 'package:garagelink/Clients%20Screens/client_vehicles_screen.dart';
import 'package:garagelink/MecanicienScreens/stock/stockPieceForm.dart';
import 'package:garagelink/auth/login.dart';
import 'package:garagelink/auth/reset_password.dart';
import 'package:garagelink/auth/signup.dart';
import 'package:garagelink/carnetEntretien/entretien_screen.dart';
import 'package:garagelink/complete_profile.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/MecanicienScreens/Facture/facture_detail_page.dart';
import 'package:garagelink/MecanicienScreens/Facture/facture_screen.dart';
import 'package:garagelink/MecanicienScreens/Gestion%20Clients/add_client.dart';
import 'package:garagelink/MecanicienScreens/Reservations/reservation_screen.dart';
import 'package:garagelink/models/atelier.dart';
import 'package:garagelink/models/user.dart';
import 'package:garagelink/vehicules/add_veh.dart';
import 'package:garagelink/MecanicienScreens/Gestion%20Clients/client_dash.dart';
import 'package:garagelink/MecanicienScreens/Gestion%20Clients/edit_client.dart';
import 'package:garagelink/vehicules/vehicule_info.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/dash_board_screen.dart';
import 'package:garagelink/MecanicienScreens/devis/creation_devis.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/historique_devis.dart';
import 'package:garagelink/MecanicienScreens/edit_localisation.dart';
import 'package:garagelink/MecanicienScreens/gestion%20mec/add_mec_screen.dart';
import 'package:garagelink/MecanicienScreens/gestion%20mec/mec_list_screen.dart';
import 'package:garagelink/MecanicienScreens/mecaHome.dart';
import 'package:garagelink/MecanicienScreens/meca_services/add_edit_service_screen.dart';
import 'package:garagelink/MecanicienScreens/meca_services/meca_services.dart';
import 'package:garagelink/MecanicienScreens/stock/stock_dashboard.dart';
// create_order_screen ne doit plus être instanciée sans argument ici,
// on l'utilisera via route en lui passant un Devis en argument.
import 'package:garagelink/MecanicienScreens/ordreTravail/create_ordre_screen.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/ordre_dash.dart';
import 'package:garagelink/models/ficheClient.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/devis.dart'; // <-- ajouté
import 'package:garagelink/splash_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../MecanicienScreens/Reservations/creerResa.dart';

class GenerateRoutes {
  static final getPages = [
    GetPage(name: AppRoutes.login, page: () => LoginPage()),
    GetPage(name: AppRoutes.signup, page: () => SignUpPage()),
    GetPage(name: AppRoutes.mecaHome, page: () => MecaHomePage()),
    //GetPage(name: AppRoutes.adminHome, page: () => AdminHomePage()),
    // GetPage(name: AppRoutes.clientHome, page: () => ClientHomeScreen()),
    GetPage(name: AppRoutes.completeProfile, page: () => CompleteProfilePage()),
    GetPage(name: AppRoutes.resetPassword, page: () => ResetPasswordPage()),
    GetPage(name: AppRoutes.splashScreen, page: () => SplashScreen()),
    GetPage(name: AppRoutes.dashboard, page: () => DashBoardScreen()),
    GetPage(name: AppRoutes.mecaServices, page: () => MecaServicesPage()),
    GetPage(name: AppRoutes.editLocalisation, page: () => EditLocalisation()),
    GetPage(name: AppRoutes.creationDevis, page: () => CreationDevisPage()),
    GetPage(name: AppRoutes.devisPreviewPage, page: () => DevisPreviewPage()),
    GetPage(name: AppRoutes.historiqueDevis, page: () => HistoriqueDevisPage()),
    GetPage(name: AppRoutes.workOrderPage, page: () => WorkOrderPage()),

    // <-- ici on exige maintenant un argument de type Devis
    GetPage(
      name: AppRoutes.createOrderScreen,
      page: () {
        final args = Get.arguments;
        if (args is Devis) {
          return CreateOrderScreen(devis: args);
        }
        // Si aucun Devis n'est fourni on affiche une page d'erreur friendly
        return Scaffold(
          appBar: AppBar(
            title: const Text('Création d\'ordre'),
            backgroundColor: const Color(0xFF357ABD),
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Impossible de créer un ordre : devis manquant.\n'
                'L\'ordre doit être créé depuis la page d\'historique des devis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      },
    ),

    GetPage(
      name: AppRoutes.addEditServiceScreen,
      page: () => AddEditServiceScreen(),
    ),
    GetPage(name: AppRoutes.stockDashboard, page: () => StockDashboard()),
    GetPage(name: AppRoutes.stockPieceFormScreen, page: () => StockPieceFormScreen()),

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
        final client = Get.arguments as FicheClient;
        return EditClientScreen(client: client);
      },
    ),
    GetPage(
      name: AppRoutes.entretienScreen,
      page: () {
        final vehiculeId = Get.arguments as String;
        return EntretienScreen(vehiculeId: vehiculeId);
      },
    ),
    //////////////// MODULE RESERVATION  //////////////////////
    GetPage(name: AppRoutes.reservationScreen, page: () => const ReservationScreen()),
    GetPage(name: AppRoutes.creerResaScreen, page: () => CreerResaScreen(garage: Get.arguments as User)),
    ////////////////// MODULE VEHICULES //////////////////////
    // GetPage(
    //   name: AppRoutes.clientVehiclesScreen,
    //   page: () => const ClientVehiclesScreen(),
    // ),
    GetPage(name: AppRoutes.clientMapScreen, page: () => ClientMapScreen()),


    //////////////// MODULE ATELIERS  //////////////////////
    GetPage(name: AppRoutes.atelierDashboard, page: () => const AtelierDashScreen()),
    GetPage(
  name: AppRoutes.modifierAtelier,
  page: () {
    final atelier = Get.arguments as Atelier;
    return ModifierAtelierScreen(atelier: atelier);
  },
),
  GetPage(name: AppRoutes.ajouterAtelier, page: () => const AjouterAtelierScreen()),

    //////////////// Reservation /////////////////////
    GetPage(name: AppRoutes.chercherGarage, page: () => const ChercherGarageScreen()),
  ];
}
