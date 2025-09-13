
class StockPiece {
  final String id;
  final String sku;
  final String nom;
  final String? barcode;
  final String uom;
  final double prixAchat;
  final double prixVente;
  final int quantite;
  final int seuilMin;
  final int? seuilMax;
  final String? emplacement;
  final DateTime updatedAt;
  final double prixUnitaire;

  const StockPiece({
    required this.id,
    required this.sku,
    required this.nom,
    this.barcode,
    required this.uom,
    required this.prixAchat,
    required this.prixVente,
    required this.quantite,
    required this.seuilMin,
    this.seuilMax,
    this.emplacement,
    required this.updatedAt,
    required this.prixUnitaire,
  });

  /// Valeur totale du stock pour cette pièce
  double get valeurStock => prixAchat * quantite;

  /// Indique si la pièce est en alerte (stock trop bas ou trop haut)
  bool get enAlerte {
    if (quantite < seuilMin) return true;
    if (seuilMax != null && quantite > seuilMax!) return true;
    return false;
  }

  /// Copie avec nouvelles valeurs
  StockPiece copyWith({
    String? id,
    String? sku,
    String? nom,
    String? barcode,
    String? uom,
    double? prixAchat,
    double? prixVente,
    int? quantite,
    int? seuilMin,
    int? seuilMax,
    String? emplacement,
    DateTime? updatedAt,
    double? prixUnitaire,
  }) {
    return StockPiece(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      nom: nom ?? this.nom,
      barcode: barcode ?? this.barcode,
      uom: uom ?? this.uom,
      prixAchat: prixAchat ?? this.prixAchat,
      prixVente: prixVente ?? this.prixVente,
      quantite: quantite ?? this.quantite,
      seuilMin: seuilMin ?? this.seuilMin,
      seuilMax: seuilMax ?? this.seuilMax,
      emplacement: emplacement ?? this.emplacement,
      updatedAt: updatedAt ?? this.updatedAt,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
    );
  }

  /// Conversion en JSON (utile si tu sync avec MongoDB/Backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'nom': nom,
      'barcode': barcode,
      'uom': uom,
      'prixAchat': prixAchat,
      'prixVente': prixVente,
      'quantite': quantite,
      'seuilMin': seuilMin,
      'seuilMax': seuilMax,
      'emplacement': emplacement,
      'updatedAt': updatedAt.toIso8601String(),
      'prixUnitaire': prixUnitaire,
    };
  }

  /// Création depuis JSON
  factory StockPiece.fromJson(Map<String, dynamic> json) {
    return StockPiece(
      id: json['id'] as String,
      sku: json['sku'] as String,
      nom: json['nom'] as String,
      barcode: json['barcode'] as String?,
      uom: json['uom'] as String,
      prixAchat: (json['prixAchat'] as num).toDouble(),
      prixVente: (json['prixVente'] as num).toDouble(),
      quantite: json['quantite'] as int,
      seuilMin: json['seuilMin'] as int,
      seuilMax: json['seuilMax'] as int?,
      emplacement: json['emplacement'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
    );
  }
}
