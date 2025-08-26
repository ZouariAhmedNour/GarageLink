import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/service_provider.dart';

class ServiceCard extends ConsumerWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActif = service.status == ServiceStatus.actif;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(10), // Reduced from 12 to 10
      child: LimitedBox(
        maxHeight: 150, // Optional: Set a reasonable max height
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Minimize height
          children: [
            // Nom + statut
            Row(
              children: [
                Expanded(child: Text(service.nomService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced from 8,4 to 6,2
                  decoration: BoxDecoration(
                    color: isActif ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(isActif ? 'Actif' : 'Inactif', style: TextStyle(color: isActif ? Colors.green : Colors.red, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4), // Reduced from 6 to 4
            // Description
            Text(service.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 4), // Reduced from 6 to 4
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(serviceProvider.notifier).toggleStatus(service.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4), // Reduced from 6 to 4
                    ),
                    child: Text(isActif ? 'Désact.' : 'Activer', style: const TextStyle(fontSize: 12)), // Shortened text and reduced font size
                  ),
                ),
                const SizedBox(width: 6), // Reduced from 8 to 6
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 16)), // Reduced icon size
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red, size: 16)), // Reduced icon size
              ],
            ),
          ],
        ),
      ),
    );
  }
}