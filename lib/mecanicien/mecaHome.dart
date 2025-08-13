import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/dashboard/screens/dash_board_screen.dart';
import 'package:garagelink/mecanicien/devis/creation_devis.dart';
import 'package:garagelink/mecanicien/edit_localisation.dart';
import 'package:garagelink/mecanicien/meca_services/meca_services.dart';
import 'package:get/get.dart';
import 'package:garagelink/configurations/app_routes.dart';

class MecaHomePage extends ConsumerWidget {
  const MecaHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return const SizedBox();
    }

    final userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';

    // 📌 Widget pour les cartes de menu
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

    // 📌 Widget pour les stats rapides
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: DefaultAppBar(title: 'Bienvenue, $userName'),
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
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Get.offAllNamed(AppRoutes.login);
                        },
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
                      buildQuickStat('CA', '15K€', Icons.euro),
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
              onTap: () => Get.to(() => CreationDevisPage ()),
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
