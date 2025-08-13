class Piece {
  final String nom;
  final double prixUnitaire;
  final int quantite;

  const Piece({required this.nom, required this.prixUnitaire, required this.quantite});

  double get total => prixUnitaire * quantite;

  Piece copyWith({String? nom, double? prixUnitaire, int? quantite}) => Piece(
        nom: nom ?? this.nom,
        prixUnitaire: prixUnitaire ?? this.prixUnitaire,
        quantite: quantite ?? this.quantite,
      );
}