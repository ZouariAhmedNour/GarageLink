import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/intervention.dart';

class ReportsService {
  /// Chiffre d’affaires : somme des factures TTC
  double chiffreAffaires(List<Facture> factures) {
    return factures.fold(0.0, (s, f) => s + (f.totalTTC));
  }

  /// Nombre total d’interventions
  int nombreInterventions(List<Intervention> interventions) {
    return interventions.length;
  }

  /// Marge = CA - coût total
  double marge(List<Facture> factures, double coutTotal) {
    final ca = chiffreAffaires(factures);
    return ca - coutTotal;
  }

  /// Taux de rotation du stock
  double tauxRotation(int piecesVendues, double stockMoyen) {
    if (stockMoyen == 0) return 0;
    return piecesVendues / stockMoyen;
  }

  /// Immobilisation = valeur moyenne du stock
  double immobilisation(double valeurStockMoyenne) => valeurStockMoyenne;

  /// Temps moyen passé à l’atelier par intervention
  Duration tempsMoyenAtelier(List<Intervention> itvs) {
    if (itvs.isEmpty) return Duration.zero;
    final total = itvs.fold<int>(0, (s, i) => s + i.dureeMinutes);
    return Duration(minutes: (total / itvs.length).round());
  }
}
