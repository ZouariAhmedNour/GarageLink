// mecanicien.dart

enum Poste {
  mecanicien,
  electricienAuto,
  carrossier,
  chefDEquipe,
  apprenti,
}

enum TypeContrat {
  cdi,
  cdd,
  stage,
  apprentissage,
}

enum Statut {
  actif,
  conge,
  arretMaladie,
  suspendu,
  demissionne,
}

enum PermisConduire {
  a,
  b,
  c,
  d,
  e,
}

class ServiceMecanicien {
  final String serviceId;
  final String name;

  ServiceMecanicien({
    required this.serviceId,
    required this.name,
  });

  factory ServiceMecanicien.fromJson(Map<String, dynamic> json) {
    return ServiceMecanicien(
      serviceId: json['serviceId']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'name': name,
    }..removeWhere((key, value) => value == null);
  }
}

class Mecanicien {
  final String? id; // _id from MongoDB
  final String nom;
  final DateTime dateNaissance;
  final String telephone;
  final String email;
  final String matricule;
  final Poste poste;
  final DateTime dateEmbauche;
  final TypeContrat typeContrat;
  final Statut statut;
  final double salaire;
  final List<ServiceMecanicien> services;
  final String experience;
  final PermisConduire permisConduire;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Mecanicien({
    this.id,
    required this.nom,
    required this.dateNaissance,
    required this.telephone,
    required this.email,
    required this.matricule,
    this.poste = Poste.mecanicien,
    required this.dateEmbauche,
    this.typeContrat = TypeContrat.cdi,
    this.statut = Statut.actif,
    required this.salaire,
    required this.services,
    required this.experience,
    this.permisConduire = PermisConduire.b,
    this.createdAt,
    this.updatedAt,
  });

  factory Mecanicien.fromJson(Map<String, dynamic> json) {
    return Mecanicien(
      id: json['_id']?.toString(),
      nom: json['nom'] ?? '',
      dateNaissance: json['dateNaissance'] != null
          ? DateTime.parse(json['dateNaissance'])
          : DateTime.now(),
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      matricule: json['matricule'] ?? '',
      poste: _parsePoste(json['poste']),
      dateEmbauche: json['dateEmbauche'] != null
          ? DateTime.parse(json['dateEmbauche'])
          : DateTime.now(),
      typeContrat: _parseTypeContrat(json['typeContrat']),
      statut: _parseStatut(json['statut']),
      salaire: (json['salaire'] as num?)?.toDouble() ?? 0.0,
      services: (json['services'] as List<dynamic>?)
              ?.map((item) => ServiceMecanicien.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      experience: json['experience'] ?? '',
      permisConduire: _parsePermisConduire(json['permisConduire']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'dateNaissance': dateNaissance.toIso8601String(),
      'telephone': telephone,
      'email': email,
      'matricule': matricule,
      'poste': poste.toString().split('.').last.replaceAll('mecanicien', 'Mécanicien').replaceAll('electricienAuto', 'Électricien Auto').replaceAll('carrossier', 'Carrossier').replaceAll('chefDEquipe', 'Chef d\'équipe').replaceAll('apprenti', 'Apprenti'),
      'dateEmbauche': dateEmbauche.toIso8601String(),
      'typeContrat': typeContrat.toString().split('.').last.toUpperCase(),
      'statut': statut.toString().split('.').last.replaceAll('actif', 'Actif').replaceAll('conge', 'Congé').replaceAll('arretMaladie', 'Arrêt maladie').replaceAll('suspendu', 'Suspendu').replaceAll('demissionne', 'Démissionné'),
      'salaire': salaire,
      'services': services.map((service) => service.toJson()).toList(),
      'experience': experience,
      'permisConduire': permisConduire.toString().split('.').last.toUpperCase(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  static Poste _parsePoste(String? poste) {
    switch (poste) {
      case 'Électricien Auto':
        return Poste.electricienAuto;
      case 'Carrossier':
        return Poste.carrossier;
      case 'Chef d\'équipe':
        return Poste.chefDEquipe;
      case 'Apprenti':
        return Poste.apprenti;
      case 'Mécanicien':
      default:
        return Poste.mecanicien;
    }
  }

  static TypeContrat _parseTypeContrat(String? type) {
    switch (type) {
      case 'CDD':
        return TypeContrat.cdd;
      case 'Stage':
        return TypeContrat.stage;
      case 'Apprentissage':
        return TypeContrat.apprentissage;
      case 'CDI':
      default:
        return TypeContrat.cdi;
    }
  }

  static Statut _parseStatut(String? statut) {
    switch (statut) {
      case 'Congé':
        return Statut.conge;
      case 'Arrêt maladie':
        return Statut.arretMaladie;
      case 'Suspendu':
        return Statut.suspendu;
      case 'Démissionné':
        return Statut.demissionne;
      case 'Actif':
      default:
        return Statut.actif;
    }
  }

  static PermisConduire _parsePermisConduire(String? permis) {
    switch (permis) {
      case 'A':
        return PermisConduire.a;
      case 'C':
        return PermisConduire.c;
      case 'D':
        return PermisConduire.d;
      case 'E':
        return PermisConduire.e;
      case 'B':
      default:
        return PermisConduire.b;
    }
  }
}