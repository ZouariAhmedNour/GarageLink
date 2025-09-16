// service.dart

enum ServiceStatut {
  actif,
  desactive,
}

class Service {
  final String? id; // _id from MongoDB
  final String serviceId; // Corresponds to 'id' field in schema
  final String name;
  final String description;
  final ServiceStatut statut;

  Service({
    this.id,
    required this.serviceId,
    required this.name,
    required this.description,
    this.statut = ServiceStatut.actif,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id']?.toString(),
      serviceId: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      statut: _parseStatut(json['statut']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': serviceId,
      'name': name,
      'description': description,
      'statut': statut.toString().split('.').last.replaceAll('actif', 'Actif').replaceAll('desactive', 'Désactivé'),
    }..removeWhere((key, value) => value == null);
  }

  static ServiceStatut _parseStatut(String? statut) {
    switch (statut) {
      case 'Désactivé':
        return ServiceStatut.desactive;
      case 'Actif':
      default:
        return ServiceStatut.actif;
    }
  }
}