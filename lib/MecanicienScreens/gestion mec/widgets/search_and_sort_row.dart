import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchAndSortRow extends ConsumerStatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String) onSortChanged;
  final Function(bool) onSortDirectionChanged;
  final String sortBy;
  final bool sortAsc;

  const SearchAndSortRow({
    super.key,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onSortDirectionChanged,
    required this.sortBy,
    required this.sortAsc,
  });

  @override
  ConsumerState<SearchAndSortRow> createState() => _SearchAndSortRowState();
}

class _SearchAndSortRowState extends ConsumerState<SearchAndSortRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher par nom ou id',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: widget.sortBy,
          items: const [
            DropdownMenuItem(value: 'nom', child: Text('Nom')),
            DropdownMenuItem(value: 'salaire', child: Text('Salaire')),
            DropdownMenuItem(value: 'anciennete', child: Text('Ancienneté')),
          ],
          onChanged: (v) => widget.onSortChanged(v!),
        ),
        IconButton(
          icon: Icon(widget.sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: () => widget.onSortDirectionChanged(!widget.sortAsc),
        ),
      ],
    );
  }
}