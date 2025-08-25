import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompetenceChips extends ConsumerStatefulWidget {
  final Function(String, bool) onCompetenceSelected;
  final Set<String> competencesFilter;

  const CompetenceChips({
    super.key,
    required this.onCompetenceSelected,
    required this.competencesFilter,
  });

  @override
  ConsumerState<CompetenceChips> createState() => _CompetenceChipsState();
}

class _CompetenceChipsState extends ConsumerState<CompetenceChips> {
  final List<String> allCompetences = [
    'moteur',
    'transmission',
    'freinage',
    'suspension',
    'élécrticité',
    'diagnostic',
    'carrosserie',
    'climatisation'
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: allCompetences.map((c) {
        final selected = widget.competencesFilter.contains(c);
        return FilterChip(
          label: Text(c),
          selected: selected,
          onSelected: (on) => widget.onCompetenceSelected(c, on),
        );
      }).toList(),
    );
  }
}