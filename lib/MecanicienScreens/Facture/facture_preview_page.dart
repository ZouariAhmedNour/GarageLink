import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/facture_api.dart';
import 'package:printing/printing.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:garagelink/providers/devis_provider.dart';

class FacturePreviewPage extends ConsumerStatefulWidget {
  final Facture facture;
  const FacturePreviewPage({super.key, required this.facture});

  @override
  ConsumerState<FacturePreviewPage> createState() => _FacturePreviewPageState();
}

class _FacturePreviewPageState extends ConsumerState<FacturePreviewPage> {
  late Future<Devis?> _devisFuture;
  Facture? _factureLocal;
  bool _refreshTried = false; // empêche boucles/retries infinies

  @override
  void initState() {
    super.initState();
    _devisFuture = _resolveDevisAndMaybeRefreshFacture();
  }

  /// Tente de recharger la facture complète via l'API si nécessaire, puis résout
  /// (embed / provider / fetch) le Devis lié à partir de la facture finale.
  Future<Devis?> _resolveDevisAndMaybeRefreshFacture() async {
    Facture current = _factureLocal ?? widget.facture;

    // Tentative initiale (présente dans initState) : si pas de services on essaye (si token dispo)
    try {
      if (current.services.isEmpty && current.id != null && current.id!.isNotEmpty) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          try {
            final refreshed = await FactureApi.getFactureById(token, current.id!);
            if (refreshed != null) {
              _factureLocal = refreshed;
              current = refreshed;
              debugPrint('Facture rafraîchie (init): services=${current.services.length}');
            }
          } catch (e) {
            debugPrint('Échec refresh init: $e');
          }
        } else {
          debugPrint('init: token indisponible, skip initial refresh.');
        }
      }
    } catch (e) {
      debugPrint('Erreur init refresh check: $e');
    }

    // Ensuite résolution du Devis à partir de la facture actuelle (possiblement rafraîchie)
    try {
      final dyn = current as dynamic;
      final dynamic maybe = dyn.devis ?? dyn.devis_object ?? dyn.devisData;
      if (maybe != null) {
        if (maybe is Devis) return maybe;
        if (maybe is Map<String, dynamic>) {
          try {
            return Devis.fromJson(maybe);
          } catch (_) {}
        } else if (maybe is String) {
          try {
            return Devis.fromJson(Map<String, dynamic>.from(json.decode(maybe)));
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Si pas d'objet embed, rechercher par devisId (cache/provider puis API)
    try {
      final dyn = current as dynamic;
      final String? devisId = (dyn.devisId ?? dyn.devis_id ?? dyn.devisID ?? dyn.devis)?.toString();
      if (devisId != null && devisId.isNotEmpty) {
        final Devis? cached = ref.read(devisByIdProvider(devisId));
        if (cached != null) return cached;
        final Devis? fetched = await ref.read(devisProvider.notifier).loadById(devisId);
        if (fetched != null) return fetched;
      }
    } catch (_) {}

    return null;
  }

  /// Méthode asynchrone pour forcer un refresh lorsque le token devient disponible.
  Future<void> _doRefreshWhenTokenAvailable(String token) async {
    if (_refreshTried) return;
    _refreshTried = true; // on marque qu'on a tenté (évite boucle)
    try {
      final current = _factureLocal ?? widget.facture;
      if (current.services.isEmpty && current.id != null && current.id!.isNotEmpty) {
        final refreshed = await FactureApi.getFactureById(token, current.id!);
        if (refreshed != null) {
          setState(() {
            _factureLocal = refreshed;
            // on recrée le future pour re-resolve le devis en fonction de la facture rafraîchie
            _devisFuture = _resolveDevisAndMaybeRefreshFacture();
          });
          debugPrint('Facture rafraîchie (on token ready): services=${refreshed.services.length}');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du refresh after token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // observe le token à chaque build
    final String? token = ref.watch(authTokenProvider);

    // si token devient disponible et que la facture initiale est vide, on déclenche un refresh asynchrone
    if (token != null && token.isNotEmpty && !_refreshTried) {
      // schedule microtask pour ne pas appeler async directement pendant build
      Future.microtask(() => _doRefreshWhenTokenAvailable(token));
    }

    final Facture factToUse = _factureLocal ?? widget.facture;
    final safeClient = (factToUse.clientInfo.nom?.isNotEmpty ?? false) ? factToUse.clientInfo.nom! : "client";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aperçu Facture"),
        actions: [
          FutureBuilder<Devis?>(
            future: _devisFuture,
            builder: (context, snap) {
              final Devis? resolved = snap.data;
              return IconButton(
                icon: const Icon(Icons.print),
                onPressed: () async {
                  try {
                    Uint8List bytes;
                    if ((factToUse.services.isEmpty) && resolved != null) {
                      bytes = await PdfService.instance.buildDevisPdfBytes(resolved, footerNote: "Généré par GarageLink");
                    } else {
                      bytes = await PdfService.instance.buildFacturePdfBytes(factToUse, footerNote: "Généré par GarageLink");
                    }
                    await PdfService.instance.printPdfBytes(bytes);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur impression: $e')));
                  }
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Devis?>(
        future: _devisFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final Devis? resolvedDevis = snap.data;
          final Facture fact = _factureLocal ?? widget.facture;

          final bool useDevisPdf = fact.services.isEmpty && resolvedDevis != null;

          if (useDevisPdf) {
            final safeClient2 = (resolvedDevis.clientName?.isNotEmpty ?? false) ? resolvedDevis.clientName! : safeClient;
            return PdfPreview(
              build: (format) => PdfService.instance.buildDevisPdfBytes(resolvedDevis!, footerNote: "Généré par GarageLink"),
              pdfFileName: "devis_for_facture_${safeClient2}.pdf",
              allowPrinting: true,
              allowSharing: true,
            );
          }

          return PdfPreview(
            build: (format) => PdfService.instance.buildFacturePdfBytes(fact, footerNote: "Généré par GarageLink"),
            pdfFileName: "facture_${safeClient}.pdf",
            allowPrinting: true,
            allowSharing: true,
          );
        },
      ),
    );
  }
}
