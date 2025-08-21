import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/mecaHome.dart';
import 'package:garagelink/mecanicien/stock/alertes_screen.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';
import 'package:get/get.dart';

class StockAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const StockAppBar({Key? key, required this.onRefresh}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: StockColors.primary,
      foregroundColor: Colors.white,
      title: SizedBox(
        width: 120, 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4), 
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dashboard,
               size: 16,
               color: Colors.white,
                ), 
            ),
            const SizedBox(width: 6), 
            const Text(
              'Stock Dash', 
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white), // Reduced font size
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
           size: 20,
          color: Colors.white,),
          onPressed: () => Get.to(() => const AlertesScreen()),
          tooltip: 'Alertes',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
          onPressed: onRefresh,
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: const Icon(Icons.home, size: 20, color: Colors.white),
          onPressed: () => Get.to(() => const MecaHomePage()),
          tooltip: 'Meca home',
        ),
        
      ],
    );
  }
}