import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom + statut
          Row(
            children: [
              Expanded(child: Text(service.nom, style: const TextStyle(fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: service.actif ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(service.actif ? 'Actif' : 'Inactif',
                    style: TextStyle(color: service.actif ? Colors.green : Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Catégorie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(service.categorie, style: const TextStyle(color: Colors.blue)),
          ),
          const SizedBox(height: 8),
          Text(service.description, maxLines: 2, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          // Prix & Durée
          Row(
            children: [
              const Icon(Icons.monetization_on, size: 16, color: Colors.green),
              Text('${service.prix}DT', style: const TextStyle(color: Colors.green)),
              const Spacer(),
              const Icon(Icons.schedule, size: 16, color: Colors.blue),
              Text('${service.duree}min', style: const TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(serviceProvider.notifier).toggleActif(service.id),
                  child: Text(service.actif ? 'Désactiver' : 'Activer'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}