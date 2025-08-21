import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/intervention.dart';

class ReportsService {
  // Exemple simplifié : calcul CA depuis une liste de factures
  double chiffreAffaires(List<Facture> factures) {
    return factures.fold(0.0, (s, f) => s + (f.montant));
  }

  int nombreInterventions(List<Intervention> interventions) {
    return interventions.length;
  }

  double marge(List<Facture> factures, double coutTotal) {
    final ca = chiffreAffaires(factures);
    return ca - coutTotal;
  }

  double tauxRotation(int piecesVendues, double stockMoyen) {
    if (stockMoyen == 0) return 0;
    return piecesVendues / stockMoyen;
  }

  double immobilisation(double valeurStockMoyenne) => valeurStockMoyenne;

  Duration tempsMoyenAtelier(List<Intervention> itvs) {
    if (itvs.isEmpty) return Duration.zero;
    final total = itvs.fold<int>(0, (s, i) => s + i.dureeMinutes); 
    return Duration(minutes: (total / itvs.length).round());
  }
}
