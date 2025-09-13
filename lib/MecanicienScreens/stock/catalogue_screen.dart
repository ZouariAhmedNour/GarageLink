import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/providers/stockpiece_provider.dart';
import 'package:get/get.dart';
import 'stockPieceForm.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});
  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final asyncStockPieces = ref.watch(stockPieceProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Catalogue des pièces',
        backgroundColor: const Color(0xFF357ABD),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher par nom ou SKU',
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: asyncStockPieces.when(
              data: (stockPieces) {
                final filtered = stockPieces.where((p) {
                  final q = query.toLowerCase();
                  return p.nom.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
                }).toList();

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final stockPiece = filtered[index];
                    return ListTile(
                      title: Text('${stockPiece.sku} • ${stockPiece.nom}'),
                      subtitle: Text(
                        'Stock: ${stockPiece.quantite} ${stockPiece.uom} | PU Achat: ${stockPiece.prixAchat.toStringAsFixed(3)}',
                      ),
                      trailing: Text('${stockPiece.valeurStock.toStringAsFixed(3)} TND'),
                      onTap: () {
                        final idx = stockPieces.indexWhere((p) => p.id == stockPiece.id);
                        if (idx != -1) {
                          Get.to(() => StockPieceFormScreen(
                                index: idx,
                                stockPiece: stockPiece,
                              ));
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const StockPieceFormScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
