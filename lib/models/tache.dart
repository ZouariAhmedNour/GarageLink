class Tache {
  String titre;
  String description;
  double tarifHoraire;
  double heures;

  Tache({
    required this.titre,
    required this.description,
    required this.tarifHoraire,
    required this.heures,
  });

  double get total => tarifHoraire * heures;
}