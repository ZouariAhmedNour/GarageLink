import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/stock/stock%20widgets/modern_kpi_card.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';
import 'package:garagelink/models/mouvement.dart';

class KpiSection extends StatelessWidget {
  final int piecesCount;
  final int alertesCount;
  final List<Mouvement> mouvements;
  final double totalValeur;

  const KpiSection({
    Key? key,
    required this.piecesCount,
    required this.alertesCount,
    required this.mouvements,
    required this.totalValeur,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recentMouvements = mouvements.where(
      (m) => m.date.isAfter(DateTime.now().subtract(const Duration(days: 30))),
    ).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ModernKpiCard(
              title: 'Pièces en stock',
              value: piecesCount.toString(),
              icon: Icons.inventory_2,
              color: StockColors.primary,
              trend: '+5%',
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
            ModernKpiCard(
              title: 'Alertes actives',
              value: alertesCount.toString(),
              icon: Icons.warning_amber,
              color: alertesCount == 0 ? StockColors.success : StockColors.warning,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
            ModernKpiCard(
              title: 'Mouvements 30j',
              value: recentMouvements.toString(),
              icon: Icons.swap_horiz,
              color: StockColors.primary,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
            ModernKpiCard(
              title: 'Valeur totale',
              value: '${totalValeur.toStringAsFixed(0)} TND',
              icon: Icons.paid,
              color: StockColors.success,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
          ],
        );
      },
    );
  }
}