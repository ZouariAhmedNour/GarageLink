
enum ServiceStatus { actif, inactif }

class Service {
  final String id;
  final String nomService;
  final String description;
  final ServiceStatus status;

  const Service({
    required this.id,
    required this.nomService,
    required this.description,
    this.status = ServiceStatus.actif,
  });

  /// Copie avec modification
  Service copyWith({
    String? id,
    String? nomService,
    String? description,
    ServiceStatus? status,
  }) {
    return Service(
      id: id ?? this.id,
      nomService: nomService ?? this.nomService,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String,
      nomService: map['nomService'] as String,
      description: map['description'] as String,
      status: map['status'] == 'inactif'
          ? ServiceStatus.inactif
          : ServiceStatus.actif,
    );
  }
}
