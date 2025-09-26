// lib/mecanicien/devis/devis_widgets/totals_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/utils/format.dart';

class TotalsCard extends ConsumerWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(devisProvider);

    final sousTotalPieces = state.sousTotalPieces;
    final mainOeuvre = state.maindoeuvre; // ✅ récupère la MO depuis provider
    final totalHTAvantRemise = state.totalHTAvantRemise;
    final remisePercent = state.remisePercent;
    final montantRemise = state.montantRemise;
    final totalHtNet = state.totalHT;        // inclut déjà MO
    final montantTva = state.montantTva;
    final totalTtc = state.totalTTC;
    final tvaRate = state.tvaRate;

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
            _row('Sous-total pièces (HT)', Fmt.money(sousTotalPieces)),
            const SizedBox(height: 6),
            _row('Main d\'œuvre (HT)', Fmt.money(mainOeuvre)), // ✅ ajout
            const Divider(height: 20),
            _row('Total HT (avant remise)', Fmt.money(totalHTAvantRemise)),
            const SizedBox(height: 6),
            _row('Remise (${remisePercent.toStringAsFixed(2)}%)', '- ${Fmt.money(montantRemise)}'),
            const Divider(height: 20),
            _row('Total HT', Fmt.money(totalHtNet), isBold: true),
            const SizedBox(height: 6),
            _row('TVA (${tvaRate.toStringAsFixed(0)}%)', Fmt.money(montantTva)),
            const Divider(height: 20),
            _row('Total TTC', Fmt.money(totalTtc), isBold: true),
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
