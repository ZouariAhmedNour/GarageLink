import 'package:flutter/material.dart';

class FrequentRepairsCard extends StatelessWidget {
  final List<Map<String, dynamic>> repairs = [
    {'type': 'Vidange', 'count': 45},
    {'type': 'Freins', 'count': 32},
    {'type': 'Pneus', 'count': 27},
    {'type': 'Courroie', 'count': 15},
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
       color: Colors.white, // 📌 Fond blanc forcé
       elevation: 4, 
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Réparations fréquentes",
                style: Theme.of(context).textTheme.titleLarge),
            ...repairs.map((r) => ListTile(
              leading: Icon(Icons.build),
              title: Text(r['type']),
              trailing: Text("${r['count']}"),
            )),
          ],
        ),
      ),
    );
  }
}
