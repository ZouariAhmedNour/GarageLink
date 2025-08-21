import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';

class StockAlerts extends StatelessWidget {
  final dynamic alertes;

  const StockAlerts({Key? key, required this.alertes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alertes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: StockColors.success),
            const SizedBox(height: 8),
            const Text('Tout va bien !', style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('Aucune alerte active', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alertes.take(4).length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = alertes[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StockColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: StockColors.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: StockColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.piece.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Stock: ${a.piece.quantite} | Min: ${a.seuilMin}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}