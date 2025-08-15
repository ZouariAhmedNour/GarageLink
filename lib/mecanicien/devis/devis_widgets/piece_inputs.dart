import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/providers/devis_provider.dart';

class PieceInputs extends ConsumerWidget {
  final bool isTablet;
  final TextEditingController pieceNomCtrl;
  final TextEditingController qteCtrl;
  final TextEditingController puCtrl;
  final String? Function(String?)? validator;

  const PieceInputs({
    super.key,
    required this.isTablet,
    required this.pieceNomCtrl,
    required this.qteCtrl,
    required this.puCtrl,
    required this.validator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isTablet
        ? Row(
            children: [
              Expanded(
                flex: 3,
                child: ModernTextField(
                  controller: pieceNomCtrl,
                  label: 'Désignation (saisie libre)',
                  icon: Icons.label,
                  validator: validator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernTextField(
                  controller: qteCtrl,
                  label: 'Qté',
                  icon: Icons.add_circle_outline,
                  keyboardType: TextInputType.number,
                  validator: validator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernTextField(
                  controller: puCtrl,
                  label: 'PU',
                  icon: Icons.money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (ref.read(devisProvider).pieces.isNotEmpty) return null;
                    if (v == null || v.isEmpty) return 'Champ requis';
                    return null;
                  },
                ),
              ),
            ],
          )
        : Column(
            children: [
              ModernTextField(
                controller: pieceNomCtrl,
                label: 'Désignation (saisie libre)',
                icon: Icons.label,
                validator: validator,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ModernTextField(
                      controller: qteCtrl,
                      label: 'Qté',
                      icon: Icons.add_circle_outline,
                      keyboardType: TextInputType.number,
                      validator: validator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernTextField(
                      controller: puCtrl,
                      label: 'PU',
                      icon: Icons.money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (ref.read(devisProvider).pieces.isNotEmpty) return null;
                        if (v == null || v.isEmpty) return 'Champ requis';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}
