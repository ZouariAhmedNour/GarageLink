// fiche_client.dart

enum ClientType {
  particulier,
  professionnel,
}

class FicheClient {
  final String? id; // _id from MongoDB
  final String nom;
  final ClientType type;
  final String adresse;
  final String telephone;
  final String email;

  FicheClient({
    this.id,
    required this.nom,
    required this.type,
    required this.adresse,
    required this.telephone,
    required this.email,
  });

  // Parse JSON to FicheClient object
  factory FicheClient.fromJson(Map<String, dynamic> json) {
    return FicheClient(
      id: json['_id']?.toString(),
      nom: json['nom'] ?? '',
      type: json['type'] == 'particulier'
          ? ClientType.particulier
          : ClientType.professionnel,
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  // Convert FicheClient object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'type': type == ClientType.particulier ? 'particulier' : 'professionnel',
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
    }..removeWhere((key, value) => value == null); // Remove null values
  }
}