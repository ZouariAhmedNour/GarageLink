class Client {
  final String id;   // Identifiant unique
  final String nom;
  final String email;
  final String tel;
  final String? numSerie;

  Client({
    required this.id,
    required this.nom,
    required this.email,
    required this.tel,
    this.numSerie,
  });
}
