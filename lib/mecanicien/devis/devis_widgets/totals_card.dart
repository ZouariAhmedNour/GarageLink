// lib/mecanicien/devis/devis_widgets/totals_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/devis_provider.dart';

import 'package:garagelink/utils/format.dart';

class TotalsCard extends ConsumerWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(devisProvider);
    final double remiseAmount = q.sousTotal - q.totalHt; // montant de la remise absolue

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4A90E2), width: 1),
      ),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ligne : Sous-total (pièces + main-d'oeuvre)
            _row('Sous-total (HT brut)', Fmt.money(q.sousTotal)),
            const SizedBox(height: 6),
            // Remise en % et montant
            _row('Remise (${(q.remise * 100).toStringAsFixed(0)}%)', '- ${Fmt.money(remiseAmount)}'),
            const Divider(height: 20),
            // Total HT après remise
            _row('Total HT', Fmt.money(q.totalHt), isBold: true),
            const SizedBox(height: 6),
            // Montant TVA
            _row('TVA (${(q.tva * 100).toStringAsFixed(0)}%)', Fmt.money(q.montantTva)),
            const Divider(height: 20),
            // Total TTC
            _row('Total TTC', Fmt.money(q.totalTtc), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      );
}
