enum TypeMouvement { entree, sortie, ajustement }


class Mouvement {
final String id;
final String pieceId;
final TypeMouvement type;
final int quantite;
final DateTime date;
final String? notes;
final String? userId;
final String? refDoc; // référence bon de livraison/inventaire, etc.


const Mouvement({
required this.id,
required this.pieceId,
required this.type,
required this.quantite,
required this.date,
this.notes,
this.userId,
this.refDoc,
});
}