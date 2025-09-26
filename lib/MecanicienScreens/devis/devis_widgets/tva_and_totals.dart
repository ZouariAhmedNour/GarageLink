// lib/mecanicien/devis/devis_widgets/tva_and_totals.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/providers/devis_provider.dart';

class TvaAndTotals extends ConsumerWidget {
  final bool isTablet;
  final TextEditingController tvaCtrl;
  final TextEditingController maindoeuvreCtrl;
  final TextEditingController? remiseCtrl; // optionnel (backward compatibility)

  const TvaAndTotals({
    Key? key,
    required this.isTablet,
    required this.tvaCtrl,
    required this.maindoeuvreCtrl,
    this.remiseCtrl,
  }) : super(key: key);

  double _parsePercent(String v) {
    final raw = v.replaceAll(',', '.').trim();
    if (raw.isEmpty) return 0.0;
    return double.tryParse(raw) ?? 0.0;
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // provider
    final notifier = ref.read(devisProvider.notifier);

    // copy nullable public field to a local variable so the analyzer can promote it
    final TextEditingController? remiseLocal = remiseCtrl;

    final leftColumn = Column(
      children: [
        ModernTextField(
          controller: tvaCtrl,
          label: 'TVA %',
          icon: Icons.percent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            // on stocke le taux en pourcentage (ex: 19.0)
            final t = _parsePercent(v);
            notifier.setTvaRate(t);
          },
        ),
        const SizedBox(height: 12),

      ],
    );

    final rightColumn = Column(
      children: [
        // Remise est optionnelle : si tu veux activer la remise côté provider,
        // il faudra ajouter setRemise(...) au provider. Ici on propose simplement le champ.
       if (remiseLocal != null) ...[
  ModernTextField(
    controller: remiseLocal,
    label: 'Remise %',
    icon: Icons.discount,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (v) {
      final r = _parsePercent(v);
      notifier.setRemise(r); // <-- met à jour le provider
    },
  ),
  const SizedBox(height: 12),
],
        // TotalsCard (séparé) lira déjà l'état du provider pour afficher les montants
      ],
    );

    return isTablet
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: 16),
              Expanded(child: rightColumn),
            ],
          )
        : Column(
            children: [
              leftColumn,
              const SizedBox(height: 12),
              rightColumn,
            ],
          );
  }
}
