import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';

class TopArticles extends StatelessWidget {
  final dynamic pieces;

  const TopArticles({Key? key, required this.pieces}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final top = [...pieces]..sort((a, b) => b.valeurStock.compareTo(a.valeurStock));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: top.take(5).length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = top[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StockColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: StockColors.primary,
                radius: 16,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${p.quantite} ${p.uom}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text('${p.valeurStock.toStringAsFixed(0)} TND',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: StockColors.success)),
            ],
          ),
        );
      },
    );
  }
}