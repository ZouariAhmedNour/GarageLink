import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/modern_panel.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/quick_actions.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/recent_mouvements.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/stock_alerts.dart';
import 'package:garagelink/MecanicienScreens/stock/stock%20widgets/top_articles.dart';
import 'package:garagelink/models/mouvement.dart';


class MainGrid extends StatelessWidget {
  final bool isWide;
  final dynamic pieces;
  final dynamic alertes;
  final List<Mouvement> mouvements;

  const MainGrid({
    Key? key,
    required this.isWide,
    required this.pieces,
    required this.alertes,
    required this.mouvements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 2 : 1,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isWide ? 1.2 : 0.8,
      children: [
        ModernPanel(
          title: 'Actions rapides',
          icon: Icons.flash_on,
          child: QuickActions(),
        ),
        ModernPanel(
          title: 'Mouvements récents',
          icon: Icons.history,
          child: RecentMouvements(mouvements: mouvements),
        ),
        ModernPanel(
          title: 'Alertes stock',
          icon: Icons.priority_high,
          child: StockAlerts(alertes: alertes),
        ),
        ModernPanel(
          title: 'Top articles',
          icon: Icons.trending_up,
          child: TopArticles(pieces: pieces),
        ),
      ],
    );
  }
}