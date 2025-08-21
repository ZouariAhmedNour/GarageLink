class Piece {
  final String id;
  final String sku;
  final String nom;
  final String? barcode;
  final String? categorie;
  final String uom;
  final double prixUnitaire;
  final double prixAchat;
  final double prixVente;
  final int quantite;
  final int seuilMin; // alerte sous ce seuil
  final int? seuilMax; // optionnel, pour surstock
  final String? emplacement; // rayon/étagère
  final String? fournisseurId; // pour lier à un fournisseur plus tard
  final DateTime? updatedAt;

  const Piece({
    required this.id,
    required this.sku,
    required this.nom,
    this.barcode,
    this.categorie,
    this.uom = 'pièce',
    this.prixAchat = 0,
    this.prixVente = 0,
    required this.prixUnitaire,
    required this.quantite,
    this.seuilMin = 0,
    this.seuilMax,
    this.emplacement,
    this.fournisseurId,
    this.updatedAt,

      });

  double get total => prixUnitaire * quantite;
  double get valeurStock => prixAchat * quantite;

  Piece copyWith({
        String? id,
        String? sku,
        String? nom,
        double? prixUnitaire,
        String? barcode,
        String? categorie,
        String? uom,
        double? prixAchat,
        double? prixVente,
        int? quantite,
        int? seuilMin,
int? seuilMax,
String? emplacement,
String? fournisseurId,
DateTime? updatedAt,
}) => Piece(
  id: id ?? this.id,
  sku: sku ?? this.sku,
  nom: nom ?? this.nom,
  barcode: barcode ?? this.barcode,
  categorie: categorie ?? this.categorie,
  uom: uom ?? this.uom,
  prixUnitaire: prixUnitaire ?? this.prixUnitaire,
  prixAchat: prixAchat ?? this.prixAchat,
  prixVente: prixVente ?? this.prixVente,
  quantite: quantite ?? this.quantite,
  seuilMin: seuilMin ?? this.seuilMin,
  seuilMax: seuilMax ?? this.seuilMax,
  emplacement: emplacement ?? this.emplacement,
  fournisseurId: fournisseurId ?? this.fournisseurId,
  updatedAt: updatedAt ?? this.updatedAt,
  );  
}
