import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/ClientsScreens/chercherGarage.dart';
import 'package:garagelink/MecanicienScreens/Reservations/client_reservations_screen.dart';
import 'package:garagelink/MecanicienScreens/Reservations/garage_reservations_screen.dart';
import 'package:garagelink/MecanicienScreens/atelier/atelier_dash.dart';
import 'package:garagelink/MecanicienScreens/devis/creation_devis.dart';
import 'package:garagelink/MecanicienScreens/edit_localisation.dart';
import 'package:garagelink/MecanicienScreens/gestion%20mec/mec_list_screen.dart';
import 'package:garagelink/MecanicienScreens/meca_services/meca_services.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/ordre_dash.dart';
import 'package:garagelink/MecanicienScreens/stock/stock_dashboard.dart';
import 'package:garagelink/providers/notification_provider.dart';
import 'package:get/get.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/MecanicienScreens/Facture/facture_screen.dart';
import 'package:garagelink/MecanicienScreens/Gestion%20Clients/client_dash.dart';
import 'package:garagelink/MecanicienScreens/Reservations/reservation_screen.dart';
import 'package:garagelink/MecanicienScreens/dashboard/screens/dash_board_screen.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/user_api.dart';

// Nouveaux imports nécessaires pour la notif
import 'package:flutter/services.dart';
import 'package:garagelink/providers/reservation_provider.dart';
import 'package:garagelink/models/reservation.dart';

class MecaHomePage extends ConsumerStatefulWidget {
  const MecaHomePage({super.key});

  @override
  ConsumerState<MecaHomePage> createState() => _MecaHomePageState();
}

class _MecaHomePageState extends ConsumerState<MecaHomePage> {
  bool _checkingAuth = true;
  String _userName = 'Utilisateur';

  // notification state
  bool _hasNotification = false;
  bool _notificationListenerRegistered = false;

  int _pendingCount = 0; // nombre actuel de demandes en attente (pour comparaison)

  // Flag pour enregistrer le listener une seule fois (doit être créé pendant build)
  bool _reservationsListenerRegistered = false;

  @override
  void initState() {
    super.initState();

    // démarre la vérification d'auth après la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());

    // IMPORTANT: ne pas appeler ref.listen ici (Riverpod exige que ref.listen soit appelé
    // dans build() d'un ConsumerWidget/ConsumerState). Le listener sera enregistré dans build().
  }

  Future<void> _initAuth() async {
    try {
      // On peut déjà vérifier mounted avant tout appel asynchrone
      if (!mounted) return;

      // charge depuis storage (peut être long)
      await ref.read(authNotifierProvider.notifier).loadFromStorage();

      // Très important : vérifier mounted *après* un await avant d'utiliser ref ou setState
      if (!mounted) return;

      final token = ref.read(authTokenProvider);
      final currentUser = ref.read(currentUserProvider);

      if (token == null || token.isEmpty) {
        if (mounted) Get.offAllNamed(AppRoutes.login);
        return;
      }

      if (currentUser == null) {
        try {
          final profile = await UserApi.getProfile(token);
          if (!mounted) return; // widget peut avoir été démonté pendant l'appel HTTP

          // mettre à jour le provider (peut aussi déclencher rebuilds)
          await ref.read(authNotifierProvider.notifier).setUser(profile);
          if (!mounted) return;

          setState(() {
            _userName = (profile.username.isNotEmpty) ? profile.username : profile.email;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _userName = 'Utilisateur');
        }
      } else {
        if (!mounted) return;
        setState(() {
          _userName = (currentUser.username.isNotEmpty) ? currentUser.username : currentUser.email;
        });
      }

      // affichage du Snack après login : protège aussi
      final args = Get.arguments;
      if (args != null && args is Map && args['justLoggedIn'] == true) {
        final message = (args['message'] as String?) ?? 'Connecté avec succès.';
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
          );
        });
      }
    } finally {
      // Passe _checkingAuth à false seulement si monté
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

  // Appelle quand l'utilisateur clique sur l'icône de notif :
  // navigate to reservations screen and mark notif as seen.
  void _onNotificationTap() {
  setState(() {
    _hasNotification = false;
  });
  // Reset global notifications
  ref.read(newNotificationProvider.notifier).state = 0;
  Get.to(() => const ReservationScreen());
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

  // construit le widget icône de notification (avec point rouge si _hasNotification)
  Widget _buildNotificationIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: _onNotificationTap,
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.notifications, size: 26, color: Colors.white),
            ),
            if (_hasNotification)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            // Optionnel: badge avec nombre
            if (_hasNotification && _pendingCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      _pendingCount > 9 ? '9+' : '$_pendingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
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

    // Enregistrer le listener une seule fois DANS build (obligatoire pour Riverpod assertions)
    if (!_reservationsListenerRegistered) {
      _reservationsListenerRegistered = true;

      ref.listen<ReservationsState>(reservationsProvider, (previous, next) {
        if (!mounted) return;

        final int prevPending = previous?.reservations.where((r) => r.status == ReservationStatus.enAttente).length ?? 0;
        final int nextPending = next.reservations.where((r) => r.status == ReservationStatus.enAttente).length;

        if (nextPending > prevPending) {
          setState(() {
            _hasNotification = true;
            _pendingCount = nextPending;
          });
          try {
            SystemSound.play(SystemSoundType.alert);
            HapticFeedback.mediumImpact();
          } catch (_) {}
        } else {
          setState(() => _pendingCount = nextPending);
        }
      });
    }

    // Enregistrer l'écouteur des notifications globales (une seule fois)
if (!_notificationListenerRegistered) {
  _notificationListenerRegistered = true;

  ref.listen<int>(newNotificationProvider, (previous, next) {
    if (!mounted) return;
    final nextCount = next ?? 0;
    if (nextCount > 0) {
      setState(() {
        _hasNotification = true;
        _pendingCount = nextCount;
      });
      try {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
      } catch (_) {}
    } else {
      setState(() {
        _hasNotification = false;
        _pendingCount = 0;
      });
    }
  });
}

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
        actions: [
          // NOTIFICATION ICON
          _buildNotificationIcon(),
        ],
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
              icon: Icons.store,
              title: 'Ateliers',
              description: 'Gestion des ateliers mécaniques',
              color: const Color.fromARGB(255, 228, 147, 25),
              onTap: () => Get.to(() => AtelierDashScreen()),
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
            buildMenuCard(
              icon: Icons.assignment,
              title: 'Chercher Garages',
              description: 'Chercher des garages à proximité',
              color: const Color.fromARGB(255, 11, 131, 187),
              onTap: () => Get.to(() => ChercherGarageScreen()),
            ),
            buildMenuCard(
              icon: Icons.chat,
              title: 'Conversation  Clients',
              description: '',
              color: const Color.fromARGB(255, 11, 131, 187),
              onTap: () => Get.to(() => ClientReservationsScreen()),
            ),
            buildMenuCard(
              icon: Icons.chat,
              title: 'Conversation  Garages',
              description: '',
              color: const Color.fromARGB(255, 11, 131, 187),
              onTap: () => Get.to(() => GarageReservationsScreen()),
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
