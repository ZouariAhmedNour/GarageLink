import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/models/piece.dart';
import 'piece_provider.dart';


class StockAlert {
final Piece piece;
final int seuilMin;
final int? seuilMax;
StockAlert(this.piece) :
seuilMin = piece.seuilMin,
seuilMax = piece.seuilMax;


bool get isLow => piece.quantite <= seuilMin;
bool get isOver => seuilMax != null && piece.quantite > (seuilMax!);
}


final stockProvider = Provider<List<StockAlert>>((ref) {
final pieces = ref.watch(pieceProvider);
return pieces.map((p) => StockAlert(p))
.where((a) => a.isLow || a.isOver)
.toList();
});