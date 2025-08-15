class CatalogItem {
  final String code;
  final String nom;
  final double prixUnitaire;
  const CatalogItem({required this.code, required this.nom, required this.prixUnitaire});
}

// Un mini catalogue mocké
const List<CatalogItem> kCatalog = [
  CatalogItem(code: 'OIL-5W30', nom: 'Huile moteur 5W30 (5L)', prixUnitaire: 95.0),
  CatalogItem(code: 'FLT-ENG', nom: 'Filtre à huile', prixUnitaire: 25.0),
  CatalogItem(code: 'BKS-SET', nom: 'Jeu plaquettes de frein', prixUnitaire: 120.0),
  CatalogItem(code: 'BAT-70AH', nom: 'Batterie 70Ah', prixUnitaire: 380.0),
  CatalogItem(code: 'WPR-BLD', nom: 'Balais d''essuie-glace (paire)', prixUnitaire: 45.0),
];
