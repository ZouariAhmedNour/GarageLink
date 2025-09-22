enum ServiceStatut {
  actif,
  desactive,
}

class Service {
  final String? id; // _id from MongoDB
  final String name;
  final String description;
  final ServiceStatut statut;

  Service({
    this.id,
    required this.name,
    required this.description,
    this.statut = ServiceStatut.actif,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final String? rawStatut = json['statut']?.toString();
    return Service(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      statut: _parseStatut(rawStatut),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'description': description,
      'statut': statutToString(statut), // méthode publique utilisée ici
    };
  }

  static ServiceStatut _parseStatut(String? statut) {
    if (statut == null) return ServiceStatut.actif;
    final s = statut.toLowerCase();
    if (s.contains('desact') || s.contains('désact')) return ServiceStatut.desactive;
    return ServiceStatut.actif;
  }

  // méthode publique => accessible depuis d'autres fichiers (ServiceApi)
  static String statutToString(ServiceStatut statut) {
    return statut == ServiceStatut.actif ? 'Actif' : 'Désactivé';
  }
}
