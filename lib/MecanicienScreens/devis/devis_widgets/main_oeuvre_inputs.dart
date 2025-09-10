import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_duree_picker.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/providers/devis_provider.dart';

class MainOeuvreInputs extends ConsumerWidget {
  final bool isTablet;
  final TextEditingController mainOeuvreCtrl;
  final Duration duree;
  final ValueChanged<Duration> onDureeChanged;

  const MainOeuvreInputs({
    super.key,
    required this.isTablet,
    required this.mainOeuvreCtrl,
    required this.duree,
    required this.onDureeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isTablet
        ? Row(
            children: [
              Expanded(
                child: ModernTextField(
                  controller: mainOeuvreCtrl,
                  label: 'Montant main d''œuvre',
                  icon: Icons.handyman,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => ref
                      .read(devisProvider.notifier)
                      .setMainOeuvre(double.tryParse(v.replaceAll(',', '.')) ?? 0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernDureePicker(
                  value: duree,
                  onChanged: onDureeChanged,
                ),
              ),
            ],
          )
        : Column(
            children: [
              ModernTextField(
                controller: mainOeuvreCtrl,
                label: 'Montant main d''œuvre',
                icon: Icons.handyman,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => ref
                    .read(devisProvider.notifier)
                    .setMainOeuvre(double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
              const SizedBox(height: 16),
              ModernDureePicker(
                value: duree,
                onChanged: onDureeChanged,
              ),
            ],
          );
  }
}