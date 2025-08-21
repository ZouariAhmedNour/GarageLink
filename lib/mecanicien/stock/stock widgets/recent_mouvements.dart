import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/stock/stock_dashboard.dart';
import 'package:garagelink/models/mouvement.dart';

class RecentMouvements extends StatelessWidget {
  final List<Mouvement> mouvements;

  const RecentMouvements({Key? key, required this.mouvements}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mouvements.isEmpty) {
      return const Center(child: Text('Aucun mouvement récent', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: mouvements.take(4).length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final m = mouvements.reversed.toList()[index];
        return MouvementTile(mouvement: m);
      },
    );
  }
}

class MouvementTile extends StatelessWidget {
  final Mouvement mouvement;

  const MouvementTile({Key? key, required this.mouvement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEntree = mouvement.type == TypeMouvement.entree;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isEntree ? StockColors.success : StockColors.warning,
            child: Icon(
              isEntree ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${mouvement.type.name} • ${mouvement.quantite}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(mouvement.date.toLocal().toString().substring(0, 16),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}