import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garagelink/mecanicien/stock/catalogue_screen.dart';
import 'package:garagelink/mecanicien/stock/mouvement_form.dart';
import 'package:garagelink/mecanicien/stock/mouvements_screen.dart';
import 'package:garagelink/mecanicien/stock/piece_form.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';
import 'package:get/get.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionButton(
          label: 'Nouvelle pièce',
          icon: Icons.add_box,
          isPrimary: true,
          onTap: () => Get.to(() => const PieceFormScreen()),
        ),
        ActionButton(
          label: 'Mouvement',
          icon: Icons.swap_vert,
          isPrimary: true,
          onTap: () => Get.to(() => const MouvementFormScreen()),
        ),
        ActionButton(
          label: 'Catalogue',
          icon: Icons.inventory,
          onTap: () => Get.to(() => const CatalogueScreen()),
        ),
        ActionButton(
          label: 'Historique',
          icon: Icons.timeline,
          onTap: () => Get.to(() => const MouvementsScreen()),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const ActionButton({Key? key, required this.label, required this.icon, required this.onTap, this.isPrimary = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? StockColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isPrimary ? Colors.white : StockColors.primary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: isPrimary ? Colors.white : StockColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}