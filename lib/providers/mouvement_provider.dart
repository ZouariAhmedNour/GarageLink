import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mouvement.dart';
import 'stockpiece_provider.dart';

class MouvementNotifier extends StateNotifier<List<Mouvement>> {
  MouvementNotifier(this.ref) : super(const []);
  final Ref ref;

  void addMouvement(Mouvement mvt) {
    ref.read(stockPieceProvider.notifier).applyMouvement(mvt);
    state = [...state, mvt];
  }

  void updateMouvement(int index, Mouvement mvt) {
    final old = state[index];
    ref.read(stockPieceProvider.notifier).revertMouvement(old);
    ref.read(stockPieceProvider.notifier).applyMouvement(mvt);

    final list = [...state];
    list[index] = mvt;
    state = list;
  }
}

final mouvementProvider =
    StateNotifierProvider<MouvementNotifier, List<Mouvement>>((ref) {
  return MouvementNotifier(ref);
});
