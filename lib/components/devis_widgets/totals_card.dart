import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/devis_provider.dart';

import 'package:garagelink/utils/format.dart';


class TotalsCard extends ConsumerWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(devisProvider);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Sous-total (pièces + main-d’œuvre)', Fmt.money(q.sousTotal)),
            const SizedBox(height: 6),
            _row('TVA (${(q.tva * 100).toStringAsFixed(0)}%)', Fmt.money(q.montantTva)),
            const Divider(height: 20),
            _row('Total TTC', Fmt.money(q.totalTtc), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      );
}