import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterRow extends ConsumerStatefulWidget {
  final Function(String) onPosteChanged;
  final Function(String) onStatutChanged;
  final Function(String) onContratChanged;
  final Function(String) onAncienneteChanged;
  final String posteFilter;
  final String statutFilter;
  final String typeContratFilter;
  final String ancienneteFilter;

  const FilterRow({
    super.key,
    required this.onPosteChanged,
    required this.onStatutChanged,
    required this.onContratChanged,
    required this.onAncienneteChanged,
    required this.posteFilter,
    required this.statutFilter,
    required this.typeContratFilter,
    required this.ancienneteFilter,
  });

  @override
  ConsumerState<FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends ConsumerState<FilterRow> {
  final List<String> posteOptions = [
    'Tous',
    'apprenti',
    'chefEquipe',
    'carrossier',
    'mecanicien',
    'electricien'
  ];
  final List<String> statutOptions = [
    'Tous',
    'actif',
    'conges',
    'arretMaladie',
    'suspendu',
    'demissionne'
  ];
  final List<String> contratOptions = [
    'Tous',
    'cdi',
    'cdd',
    'stage',
    'apprentissage'
  ];
  final List<String> ancienneteOptions = [
    'Tous',
    '<1',
    '1-3',
    '3-5',
    '5+',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          DropdownButton<String>(
            value: widget.posteFilter,
            items: posteOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => widget.onPosteChanged(v!),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: widget.statutFilter,
            items: statutOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => widget.onStatutChanged(v!),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: widget.typeContratFilter,
            items: contratOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => widget.onContratChanged(v!),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: widget.ancienneteFilter,
            items: ancienneteOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => widget.onAncienneteChanged(v!),
          ),
        ],
      ),
    );
  }
}