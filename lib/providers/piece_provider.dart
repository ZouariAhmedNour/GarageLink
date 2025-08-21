import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/models/piece.dart';
import '../models/mouvement.dart';


class PieceNotifier extends StateNotifier<List<Piece>> {
PieceNotifier() : super(const []);


// CRUD basique
void addPiece(Piece piece) => state = [...state, piece];


void updatePiece(int index, Piece piece) {
final newList = [...state];
newList[index] = piece.copyWith(updatedAt: DateTime.now());
state = newList;
}


void deletePiece(int index) {
final newList = [...state]..removeAt(index);
state = newList;
}


// Helpers
Piece? byId(String id) => state.firstWhere((p) => p.id == id, orElse: () => null as Piece);


// Logique métier: appliquer / annuler un mouvement sur le stock
void applyMouvement(Mouvement mvt) {
final idx = state.indexWhere((p) => p.id == mvt.pieceId);
if (idx == -1) return;


final current = state[idx];
int newQt = current.quantite;
switch (mvt.type) {
case TypeMouvement.entree:
newQt += mvt.quantite;
break;
case TypeMouvement.sortie:
newQt -= mvt.quantite;
break;
case TypeMouvement.ajustement:
newQt = mvt.quantite; // interprétation: ajustement = fixer la quantité
break;
}
if (newQt < 0) newQt = 0; // garde-fou


final updated = current.copyWith(quantite: newQt, updatedAt: DateTime.now());
final list = [...state];
list[idx] = updated;
state = list;
}


void revertMouvement(Mouvement mvt) {
// annule l'effet d'un mouvement (utile lors d'une modif)
final inverse = Mouvement(
id: 'revert-${mvt.id}',
pieceId: mvt.pieceId,
type: mvt.type == TypeMouvement.entree
? TypeMouvement.sortie
: mvt.type == TypeMouvement.sortie
? TypeMouvement.entree
: TypeMouvement.ajustement,
quantite: mvt.quantite,
date: DateTime.now(),
notes: 'Revert',
);
if (mvt.type == TypeMouvement.ajustement) {
// pour un ajustement, on ne peut pas deviner l'ancienne quantité.
// dans un vrai système, il faut recharger l'ancienne valeur depuis l'audit.
return;
}
applyMouvement(inverse);
}
}

final pieceProvider = StateNotifierProvider<PieceNotifier, List<Piece>>((ref) {
return PieceNotifier();
});


// Sélecteurs et KPIs
final totalValeurStockProvider = Provider<double>((ref) {
final pieces = ref.watch(pieceProvider);
return pieces.fold(0.0, (sum, p) => sum + p.valeurStock);
});


final lowStockCountProvider = Provider<int>((ref) {
final pieces = ref.watch(pieceProvider);
return pieces.where((p) => p.quantite <= p.seuilMin).length;
});