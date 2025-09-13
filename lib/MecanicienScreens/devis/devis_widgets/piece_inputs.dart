import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_text_field.dart';
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
    // helper validator for PU field:
    String? puValidator(String? v) {
      final hasServices = ref.read(devisProvider).services.isNotEmpty;
      if (hasServices) return null; // si on a déjà des lignes, PU optionnel
      if (v == null || v.isEmpty) return 'Champ requis';
      // try parse number
      final normalized = v.replaceAll(',', '.').trim();
      final parsed = double.tryParse(normalized);
      if (parsed == null) return 'Valeur numérique requise';
      if (parsed < 0) return 'Valeur invalide';
      return null;
    }

    // helper validator for QTE field (ensure positive int)
    String? qteValidator(String? v) {
      if (validator != null) {
        final res = validator!(v);
        if (res != null) return res;
      }
      if (v == null || v.isEmpty) return 'Champ requis';
      final parsed = int.tryParse(v.trim());
      if (parsed == null || parsed <= 0) return 'Entier positif requis';
      return null;
    }

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
                  validator: qteValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernTextField(
                  controller: puCtrl,
                  label: 'PU',
                  icon: Icons.money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: puValidator,
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
                      validator: qteValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernTextField(
                      controller: puCtrl,
                      label: 'PU',
                      icon: Icons.money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: puValidator,
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}
