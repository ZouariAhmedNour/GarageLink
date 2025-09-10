import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/stock/alertes_screen.dart';
import 'package:garagelink/MecanicienScreens/stock/catalogue_screen.dart';
import 'package:garagelink/MecanicienScreens/stock/mouvements_screen.dart';
import 'package:garagelink/MecanicienScreens/stock/stock_dashboard.dart';
import 'package:get/get.dart';

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [StockColors.primary, StockColors.primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.inventory, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Stock Manager', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('GarageLink Pro', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            DrawerTile(Icons.dashboard, 'Dashboard', true, () => Navigator.pop(context)),
            DrawerTile(Icons.inventory_2, 'Catalogue', false, () => Get.to(() => const CatalogueScreen())),
            DrawerTile(Icons.swap_horiz, 'Mouvements', false, () => Get.to(() => const MouvementsScreen())),
            DrawerTile(Icons.warning_amber, 'Alertes', false, () => Get.to(() => const AlertesScreen())),
          ],
        ),
      ),
    );
  }
}

class DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const DrawerTile(this.icon, this.title, this.isActive, this.onTap, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}