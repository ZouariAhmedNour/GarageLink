

enum Poste { apprenti, chefEquipe, carrossier, mecanicien, electricien }
enum TypeContrat { cdi, cdd, stage, apprentissage }
enum Statut { actif, conges, arretMaladie, suspendu, demissionne }


enum Service {
  entretien,
  diagnostic,
  revision,
  depannage,
  electricite,
  carrosserie,
  climatisation,
}

// Extension pour avoir le label lisible
extension ServiceExtension on Service {
  String get label {
    switch (this) {
      case Service.entretien:
        return "Entretien";
      case Service.diagnostic:
        return "Diagnostic";
      case Service.revision:
        return "Révision";
      case Service.depannage:
        return "Dépannage";
      case Service.electricite:
        return "Électricité";
      case Service.carrosserie:
        return "Carrosserie";
      case Service.climatisation:
        return "Climatisation";
    }
  }
}
class Mecanicien {
  final String id;
  final String nom;
  final DateTime? dateNaissance;
  final String telephone;
  final String email;
  final String matricule;
  final Poste poste;
  final DateTime? dateEmbauche;
  final TypeContrat typeContrat;
  final Statut statut;
  final int salaire;
  final List<Service> services;
  final String experience;
  final String permisConduite;

  Mecanicien({
    required this.id,
    required this.nom,
    this.dateNaissance,
    required this.telephone,
    required this.email,
    required this.matricule,
    required this.poste,
    this.dateEmbauche,
    required this.typeContrat,
    required this.statut,
    required this.salaire,
    required this.services,
    required this.experience,
    required this.permisConduite,
  });

  Mecanicien copyWith({
    String? id,
    String? nom,
    DateTime? dateNaissance,
    String? telephone,
    String? email,
    String? matricule,
    Poste? poste,
    DateTime? dateEmbauche,
    TypeContrat? typeContrat,
    Statut? statut,
    int? salaire,
    List<Service>? services,
    String? experience,
    String? permisConduite,
  }) {
    return Mecanicien(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      matricule: matricule ?? this.matricule,
      poste: poste ?? this.poste,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      typeContrat: typeContrat ?? this.typeContrat,
      statut: statut ?? this.statut,
      salaire: salaire?.toInt() ?? this.salaire,
      services: services ?? List.from(this.services),
      experience: experience ?? this.experience,
      permisConduite: permisConduite ?? this.permisConduite,
    );
  }
}
