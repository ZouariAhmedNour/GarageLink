class Client {
  final String nom;
  final String email;
  final String tel;
  final String? numSerie;

  Client({
    required this.nom,
    required this.email,
    required this.tel,
    this.numSerie,
  });
}