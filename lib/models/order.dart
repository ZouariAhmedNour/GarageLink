// models/order.dart
class WorkOrder {
  final String id;                // Identifiant unique
  final String clientId;          // Référence vers Client.id
  final String immatriculation;   // Immatriculation du véhicule
  final DateTime date;            // Date de création de l'ordre
  final DateTime dateDebut;       // Date de début prévue
  final String service;           // Service demandé
  final String atelier;           // Atelier concerné
  final String description;       // Description du problème ou demande
  final String mecanicien;        // Mécanicien assigné
  final String status;            // Statut (En attente, En cours, Terminé)

  WorkOrder({
    required this.id,
    required this.clientId,
    required this.immatriculation,
    required this.date,
    required this.dateDebut,
    required this.service,
    required this.atelier,
    required this.description,
    required this.mecanicien,
    required this.status,
  });

  WorkOrder copyWith({
    String? clientId,
    String? immatriculation,
    DateTime? date,
    DateTime? dateDebut,
    String? service,
    String? atelier,
    String? description,
    String? mecanicien,
    String? status,
  }) {
    return WorkOrder(
      id: id,
      clientId: clientId ?? this.clientId,
      immatriculation: immatriculation ?? this.immatriculation,
      date: date ?? this.date,
      dateDebut: dateDebut ?? this.dateDebut,
      service: service ?? this.service,
      atelier: atelier ?? this.atelier,
      description: description ?? this.description,
      mecanicien: mecanicien ?? this.mecanicien,
      status: status ?? this.status,
    );
  }
}
