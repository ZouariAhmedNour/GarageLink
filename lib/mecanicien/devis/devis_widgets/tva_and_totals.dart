// lib/mecanicien/devis/devis_widgets/tva_and_totals.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/totals_card.dart';
import 'package:garagelink/providers/devis_provider.dart';

class TvaAndTotals extends ConsumerWidget {
  final bool isTablet;
  final TextEditingController tvaCtrl;
  final TextEditingController remiseCtrl;

  const TvaAndTotals({
    super.key,
    required this.isTablet,
    required this.tvaCtrl,
    required this.remiseCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isTablet
        ? Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ModernTextField(
                      controller: tvaCtrl,
                      label: 'TVA %',
                      icon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final t = (double.tryParse(v) ?? 0) / 100.0;
                        ref.read(devisProvider.notifier).setTva(t);
                      },
                    ),
                    const SizedBox(height: 12),
                    ModernTextField(
                      controller: remiseCtrl,
                      label: 'Remise %',
                      icon: Icons.discount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final r = (double.tryParse(v) ?? 0) / 100.0;
                        ref.read(devisProvider.notifier).setRemise(r);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: TotalsCard()),
            ],
          )
        : Column(
            children: [
              ModernTextField(
                controller: tvaCtrl,
                label: 'TVA %',
                icon: Icons.percent,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  final t = (double.tryParse(v) ?? 0) / 100.0;
                  ref.read(devisProvider.notifier).setTva(t);
                },
              ),
              const SizedBox(height: 12),
              ModernTextField(
                controller: remiseCtrl,
                label: 'Remise %',
                icon: Icons.discount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  final r = (double.tryParse(v) ?? 0) / 100.0;
                  ref.read(devisProvider.notifier).setRemise(r);
                },
              ),
              const SizedBox(height: 16),
              TotalsCard(),
            ],
          );
  }
}
