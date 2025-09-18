import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/creation_devis.dart';
import 'package:garagelink/MecanicienScreens/edit_localisation.dart';
import 'package:garagelink/MecanicienScreens/gestion%20mec/mec_list_screen.dart';
import 'package:garagelink/MecanicienScreens/meca_services/meca_services.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/work_order_page.dart';
import 'package:garagelink/MecanicienScreens/stock/stock_dashboard.dart';
import 'package:get/get.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/MecanicienScreens/Facture/facture_screen.dart';
import 'package:garagelink/MecanicienScreens/Gestion%20Clients/client_dash.dart';
import 'package:garagelink/MecanicienScreens/R%C3%A9servations/reservation_screen.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/dash_board_screen.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/user_api.dart';

class MecaHomePage extends ConsumerStatefulWidget {
  const MecaHomePage({super.key});

  @override
  ConsumerState<MecaHomePage> createState() => _MecaHomePageState();
}

class _MecaHomePageState extends ConsumerState<MecaHomePage> {
  bool _checkingAuth = true;
  String _userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    // démarre la vérification d'auth après la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());
  }

  Future<void> _initAuth() async {
    try {
      // Charger depuis secure storage si besoin
      await ref.read(authNotifierProvider.notifier).loadFromStorage();

      final token = ref.read(authTokenProvider);
      final currentUser = ref.read(currentUserProvider);

      if (token == null || token.isEmpty) {
        // pas de token -> redirection vers login
        if (mounted) Get.offAllNamed(AppRoutes.login);
        return;
      }

      // si l'utilisateur n'est pas dans le provider, tenter de récupérer via API
      if (currentUser == null) {
        try {
          final profile = await UserApi.getProfile(token);
          if (profile != null) {
            // mettre à jour le provider
            await ref.read(authNotifierProvider.notifier).setUser(profile);
            setState(() {
              _userName = (profile.username.isNotEmpty) ? profile.username : profile.email;
            });
          } else {
            setState(() => _userName = 'Utilisateur');
          }
        } catch (_) {
          // en cas d'erreur on continue avec valeur par défaut
          setState(() => _userName = 'Utilisateur');
        }
      } else {
        setState(() {
          _userName = (currentUser.username.isNotEmpty) ? currentUser.username : currentUser.email;
        });
      }

      // afficher message si on vient d'un login
      final args = Get.arguments;
      if (args != null && args is Map && args['justLoggedIn'] == true) {
        final message = (args['message'] as String?) ?? 'Connecté avec succès.';
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      }
    } finally {
      if (mounted) setState(() => _checkingAuth = false);
    }
  }

  Future<void> _handleLogout() async {
    // clear state + secure storage
    await ref.read(authNotifierProvider.notifier).clear();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.offAllNamed(AppRoutes.login);
      });
    }
  }

  // Widgets auxiliaires (repris de ton code)
  Widget buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildQuickStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
     final token = ref.read(authNotifierProvider).token;
  print('Token actuel: $token'); // pour debug
    // tant que l'auth est vérifiée, affiche loader
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Bienvenue, $_userName',
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 👋 HEADER DE BIENVENUE
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF357ABD),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.build_circle,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tableau de Bord',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez votre garage efficacement',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      buildQuickStat('Services', '12', Icons.build),
                      const SizedBox(width: 20),
                      buildQuickStat('Clients', '48', Icons.people),
                      const SizedBox(width: 20),
                      buildQuickStat('CA', '15KDT', Icons.money),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 📋 MENU
            const Text(
              'Menu Principal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),

            buildMenuCard(
              icon: Icons.dashboard,
              title: 'Tableau de Bord',
              description: 'Vue d\'ensemble de votre activité',
              color: const Color(0xFF4A90E2),
              onTap: () => Get.to(() => const DashBoardScreen()),
            ),
            buildMenuCard(
              icon: Icons.event,
              title: 'Réservations',
              description: 'Gérer vos réservations',
              color: const Color(0xFF4A90E2),
              onTap: () => Get.to(() => const ReservationScreen()),
            ),
            buildMenuCard(
              icon: Icons.build,
              title: 'Services',
              description: 'Gestion des services mécaniques',
              color: const Color(0xFF34C759),
              onTap: () => Get.to(() => MecaServicesPage()),
            ),
            buildMenuCard(
              icon: Icons.location_on,
              title: 'Localisation',
              description: 'Gestion de la localisation de votre garage',
              color: const Color.fromARGB(255, 240, 62, 18),
              onTap: () => Get.to(() => EditLocalisation()),
            ),
            buildMenuCard(
              icon: Icons.receipt,
              title: 'Devis',
              description: 'Création et gestion des devis',
              color: const Color.fromARGB(255, 243, 228, 20),
              onTap: () => Get.to(() => CreationDevisPage()),
            ),
            buildMenuCard(
              icon: Icons.inventory,
              title: 'Stock',
              description: 'Création et gestion du stock',
              color: const Color.fromARGB(255, 3, 8, 22),
              onTap: () => Get.to(() => StockDashboard()),
            ),
            buildMenuCard(
              icon: Icons.assignment_ind_sharp,
              title: 'Mécaniciens',
              description: 'Création et gestion des mécaniciens',
              color: const Color.fromARGB(255, 17, 50, 141),
              onTap: () => Get.to(() => MecListScreen()),
            ),
            buildMenuCard(
              icon: Icons.person,
              title: 'Clients',
              description: 'Création et gestion des clients',
              color: const Color.fromARGB(255, 134, 64, 6),
              onTap: () => Get.to(() => ClientDash()),
            ),
            buildMenuCard(
              icon: Icons.fact_check,
              title: 'Factures',
              description: 'Création et gestion des factures',
              color: const Color.fromARGB(255, 11, 131, 187),
              onTap: () => Get.to(() => FactureScreen()),
            ),
            buildMenuCard(
              icon: Icons.assignment,
              title: 'Ordres',
              description: 'Création et gestion des Ordres',
              color: const Color.fromARGB(255, 11, 131, 187),
              onTap: () => Get.to(() => WorkOrderPage()),
            ),

            // 🚀 FUTURES FONCTIONNALITÉS
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.upcoming, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Prochainement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Gestion des clients\n• Facturation\n• Inventaire des pièces\n• Planification RDV\n• Rapports détaillés',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
