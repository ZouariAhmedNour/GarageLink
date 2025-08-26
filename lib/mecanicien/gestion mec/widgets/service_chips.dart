import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServicesChips extends ConsumerStatefulWidget {
  final Function(String, bool) onServiceSelected;
  final Set<String> servicesFilter;

  const ServicesChips({
    super.key,
    required this.onServiceSelected,
    required this.servicesFilter,
  });

  @override
  ConsumerState<ServicesChips> createState() => _ServiceChipsState();
}

class _ServiceChipsState extends ConsumerState<ServicesChips> {
  final List<String> allServices = [
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
      children: allServices.map((c) {
        final selected = widget.servicesFilter.contains(c);
        return FilterChip(
          label: Text(c),
          selected: selected,
          onSelected: (on) => widget.onServiceSelected(c, on),
        );
      }).toList(),
    );
  }
}