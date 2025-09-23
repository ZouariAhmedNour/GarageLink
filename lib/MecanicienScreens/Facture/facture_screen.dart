import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/factures_provider.dart';
import 'package:garagelink/services/devis_api.dart';
import 'package:intl/intl.dart';

class FactureScreen extends ConsumerStatefulWidget {
  const FactureScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FactureScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends ConsumerState<FactureScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange? _range;
  final _searchCtrl = TextEditingController();

  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  static const primaryColor = Color(0xFF357ABD);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const successColor = Color(0xFF38A169);
  static const warningColor = Color(0xFFF56500);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();

    // charge initial des factures
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facturesProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : primaryColor,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: selected,
        selectedColor: primaryColor,
        backgroundColor: cardColor,
        side: BorderSide(color: selected ? primaryColor : Colors.grey[300]!),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }

  Widget _buildSearchCard(Widget child) {
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (_) {
        HapticFeedback.selectionClick();
        onChanged?.call();
      },
    );
  }

 Widget _buildFactureCard(dynamic facture, int index) {
  final clientName = (facture is Facture ? (facture.clientInfo.nom) : (facture['clientInfo']?['nom'])) ?? 'Client';
  final invoiceDate = (facture is Facture ? (facture.invoiceDate) : (facture['invoiceDate'])) ?? DateTime.now();
  final montant = (facture is Facture ? (facture.totalTTC) : (facture['totalTTC'])) ?? 0.0;
  final displayId = (facture is Facture && (facture.numeroFacture?.toString().isNotEmpty ?? false))
      ? facture.numeroFacture.toString()
      : ((facture is Facture) ? (facture.id?.toString() ?? '') : (facture['_id']?.toString() ?? facture['id']?.toString() ?? ''));

  final String vehicleInfo = (facture is Facture ? (facture.vehicleInfo ?? '') : (facture['vehicleInfo']?.toString() ?? '')).trim();

  return AnimatedContainer(
    duration: Duration(milliseconds: 300 + (index * 30)),
    child: Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          HapticFeedback.lightImpact();

          debugPrint('--- tap facture ---');
          debugPrint('facture.runtimeType = ${facture.runtimeType}');
          try {
            if (facture is Facture) {
              debugPrint('facture.toJson() = ${(facture as dynamic).toJson()}');
            } else {
              debugPrint('facture raw = $facture');
            }
          } catch (_) {}

          // helpers locaux
          String? _extractId(dynamic raw) {
            try {
              if (raw == null) return null;
              if (raw is String && raw.isNotEmpty) return raw;
              if (raw is Map) {
                if (raw.containsKey(r'$oid')) return raw[r'$oid']?.toString();
                final cand = raw['_id'] ?? raw['id'] ?? raw['devisId'] ?? raw['id_str'] ?? raw['ID'];
                if (cand != null) return cand.toString();
              }
              return raw.toString();
            } catch (_) {
              return null;
            }
          }

          // ---------------------------
          // _toMapIfPossible améliorée :
          // - gère Map, Map<String,dynamic>, String JSON
          // - gère Devis (appel toJson())
          // - retourne Map<String,dynamic>? ou null
          // ---------------------------
          Map<String, dynamic>? _toMapIfPossible(dynamic d) {
            try {
              if (d == null) return null;

              // si déjà Map<String, dynamic>
              if (d is Map<String, dynamic>) return d;

              // Map générique -> cast safe
              if (d is Map) return Map<String, dynamic>.from(d);

              // si c'est une instance de Devis -> utiliser toJson()
              if (d is Devis) {
                try {
                  final jsonMap = (d as dynamic).toJson();
                  if (jsonMap is Map<String, dynamic>) return Map<String, dynamic>.from(jsonMap);
                  if (jsonMap is Map) return Map<String, dynamic>.from(jsonMap);
                } catch (_) {
                  // si toJson n'existe pas ou échoue, continuer
                }
              }

              // si c'est une String -> tenter decode JSON
              if (d is String) {
                try {
                  final parsed = json.decode(d);
                  if (parsed is Map<String, dynamic>) return parsed;
                  if (parsed is Map) return Map<String, dynamic>.from(parsed);
                } catch (_) {
                  // not JSON
                }
              }

              return null;
            } catch (e) {
              debugPrint('Erreur _toMapIfPossible: $e');
              return null;
            }
          }

          // 1) essayer d'extraire un objet Devis embedded ou un devisId
          Devis? foundDevis;
          String? devisId;

          try {
            if (facture is Facture) {
              // l'objet Facture (classe)
              final dyn = facture as dynamic;
              final dynamic possible = dyn.devis ?? dyn.devis_object ?? dyn.devisData;
              if (possible != null) {
                if (possible is Devis) {
                  foundDevis = possible;
                  devisId = _extractId(possible.id ?? possible.devisId);
                } else {
                  final parsed = _toMapIfPossible(possible);
                  if (parsed != null) {
                    try {
                      foundDevis = Devis.fromJson(parsed);
                    } catch (_) {}
                    devisId = _extractId(parsed);
                  } else {
                    devisId = _extractId(possible);
                  }
                }
              } else {
                // pas d'objet embed, tenter champs id
                devisId = _extractId(dyn.devisId ?? dyn.devis_id ?? dyn.devisID ?? dyn.devis);
              }
            } else {
              // facture est Map ou autre dynamique (API raw)
              final m = _toMapIfPossible(facture) ?? <String, dynamic>{};
              final possibleObj = m['devis'] ?? m['devisObject'] ?? m['devisId'] ?? m['devis_id'] ?? m['devisData'];
              if (possibleObj != null) {
                if (possibleObj is Devis) {
                  foundDevis = possibleObj;
                  devisId = _extractId(possibleObj.id ?? possibleObj.devisId);
                } else {
                  final parsed = _toMapIfPossible(possibleObj);
                  if (parsed != null) {
                    try {
                      foundDevis = Devis.fromJson(parsed);
                    } catch (_) {}
                    devisId = _extractId(parsed);
                  } else {
                    devisId = _extractId(possibleObj);
                  }
                }
              } else {
                // prendre devisId direct depuis la map facture
                devisId = _extractId(m['devisId'] ?? m['devis'] ?? m['devis_id'] ?? m['_devis'] ?? m['devisID']);
              }
            }
          } catch (e, st) {
            debugPrint('Erreur extraction devisId/from facture: $e\n$st');
            devisId = null;
          }

          debugPrint('foundDevis=${foundDevis != null}, resolved devisId: $devisId');

          // Si on a déjà un Devis complet -> ouvrir preview Devis
         if (foundDevis != null) {
  debugPrint('foundDevis initial services.length = ${foundDevis.services.length}');
  // Si le devis embarqué a déjà des lignes -> on ouvre directement
  if (foundDevis.services.isNotEmpty) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: foundDevis)));
    return;
  }

  // Si le devis embarqué est PARTIEL (services vides) -> tenter de récupérer une version complète
  // priorité: cache provider -> notifier.loadById -> API direct
  if (devisId == null || devisId.isEmpty) {
    // pas d'id disponible : on ouvre quand même le preview avec l'objet partiel
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Devis embarqué partiel : impossible de charger les lignes (id manquant).'), duration: Duration(seconds: 3)),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: foundDevis)));
    return;
  }

  // show loader modal
  if (!mounted) return;
  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

  try {
    // 1) tenter cache local via provider.family
    Devis? fullFromCache;
    try {
      fullFromCache = ref.read(devisByIdProvider(devisId));
    } catch (_) {
      fullFromCache = null;
    }
    if (fullFromCache != null && fullFromCache.services.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: fullFromCache)));
      return;
    }

    // 2) tenter via notifier.loadById (mettra à jour le cache si réussi)
    Devis? fetched;
    try {
      fetched = await ref.read(devisProvider.notifier).loadById(devisId);
    } catch (e) {
      debugPrint('loadById threw: $e');
      fetched = null;
    }

    if (fetched != null && fetched.services.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: fetched)));
      return;
    }

    // 3) appel API direct (fallback, debug)
    try {
      final raw = await DevisApi.getDevisById(ref.read(authTokenProvider)!, devisId);
      debugPrint('Direct API response runtimeType=${raw.runtimeType}');
      debugPrint('Direct API response raw: $raw');

      // on utilise ta fonction _toMapIfPossible existante (ou adapte ici) pour convertir raw -> Map
      final Map<String, dynamic>? maybeMap = _toMapIfPossible(raw);
      if (maybeMap != null) {
        try {
          final Devis dd = Devis.fromJson(maybeMap);
          if (dd.services.isNotEmpty) {
            if (!mounted) return;
            Navigator.of(context).pop();
            Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: dd)));
            return;
          } else {
            debugPrint('API returned Devis but services still empty');
          }
        } catch (e) {
          debugPrint('Parsing API raw -> Devis failed: $e');
        }
      }
    } catch (apiErr) {
      debugPrint('Direct API call failed: $apiErr');
    }

    // Si on arrive ici : récupération impossible / devis sans lignes -> informer et ouvrir preview partiel
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible de charger les lignes du devis — affichage partiel.'), duration: Duration(seconds: 4)),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: foundDevis)));
    return;
  } catch (e) {
    try {
      Navigator.of(context).pop();
    } catch (_) {}
    debugPrint('Erreur lors du fetch complet du devis: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors du chargement du devis, ouverture partielle.')));
    Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: foundDevis)));
    return;
  }
}

          // Si pas d'id, on ouvre la preview Facture directement
          if (devisId == null || devisId.isEmpty) {
            debugPrint('aucun devisId trouvé -> ouverture preview facture');
            if (!mounted) return;

            // construire un Facture si possible
            Facture? factToSend;
            try {
              if (facture is Facture) {
                factToSend = facture;
              } else {
                final Map<String, dynamic>? m = _toMapIfPossible(facture);
                if (m != null) factToSend = Facture.fromJson(m);
              }
            } catch (e) {
              debugPrint('Impossible de convertir la facture en objet Facture: $e');
              factToSend = null;
            }

            Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(facture: factToSend)));
            return;
          }

          // Sinon on a un devisId -> tentative : cache -> provider -> API direct
          if (!mounted) return;
          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

          try {
            // 1) cache local via provider.family
            Devis? mem;
            try {
              mem = ref.read(devisByIdProvider(devisId));
            } catch (_) {
              mem = null;
            }
            if (mem != null) {
              if (!mounted) return;
              Navigator.of(context).pop(); // fermer loader
              Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: mem)));
              return;
            }

            // 2) fetch via notifier (met à jour cache si succeed)
            Devis? fetched;
            try {
              fetched = await ref.read(devisProvider.notifier).loadById(devisId);
            } catch (e) {
              debugPrint('loadById threw: $e');
              fetched = null;
            }

            if (!mounted) return;
            Navigator.of(context).pop(); // fermer loader

            if (fetched != null) {
              if (!mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: fetched)));
              return;
            }

            // 3) fallback: call direct API for debugging (no navigation)
            try {
              final raw = await DevisApi.getDevisById(ref.read(authTokenProvider)!, devisId);
              debugPrint('Direct API response runtimeType=${raw.runtimeType}');
              debugPrint('Direct API response raw: $raw');

              // utilise _toMapIfPossible: gère Map OR Devis OR String JSON
              final Map<String, dynamic>? maybeMap = _toMapIfPossible(raw);
              if (maybeMap != null) {
                try {
                  final Devis dd = Devis.fromJson(maybeMap);
                  if (!mounted) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(devis: dd)));
                  return;
                } catch (_) {
                  // ignore parse error
                }
              }
            } catch (apiErr) {
              debugPrint('Direct API call failed: $apiErr');
            }

            // Si on arrive ici -> devis introuvable : informer l'utilisateur et ouvrir preview facture
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Devis lié introuvable. Vérifie le champ devisId dans la facture ou la réponse API.'), duration: Duration(seconds: 4)),
            );

            // construire objet Facture et ouvrir preview facture
            Facture? factToSend;
            try {
              if (facture is Facture) {
                factToSend = facture;
              } else {
                final Map<String, dynamic>? m = _toMapIfPossible(facture);
                if (m != null) factToSend = Facture.fromJson(m);
              }
            } catch (e) {
              debugPrint('Impossible de convertir la facture en objet Facture (fallback): $e');
              factToSend = null;
            }

            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(facture: factToSend)));
          } catch (e) {
            // assure fermeture loader
            try {
              Navigator.of(context).pop();
            } catch (_) {}
            debugPrint('Erreur récupération devis: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la récupération du devis')));
            // fallback : ouvrir preview facture
            Facture? factToSend;
            try {
              if (facture is Facture) {
                factToSend = facture;
              } else {
                final Map<String, dynamic>? m = _toMapIfPossible(facture);
                if (m != null) factToSend = Facture.fromJson(m);
              }
            } catch (_) {
              factToSend = null;
            }
            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => DevisPreviewPage(facture: factToSend)));
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône facture
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.12),
                      primaryColor.withOpacity(0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),

              // Partie gauche: nom client + date + véhicule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom client
                    Text(
                      clientName ?? 'Client',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          (invoiceDate is DateTime) ? DateFormat.yMd().format(invoiceDate) : invoiceDate.toString(),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Véhicule
                    if (vehicleInfo.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              vehicleInfo,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Partie droite: montant + numéro facture + flèche
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(montant is double ? montant : (double.tryParse(montant.toString()) ?? 0.0)).toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: successColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: Text(
                      displayId,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}





  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facturesProvider); // FactureFilterState
    final notifier = ref.read(facturesProvider.notifier);
    final list = state.factures;

    final fadeAnim = _fadeAnimation ?? AlwaysStoppedAnimation<double>(1.0);
    final slideAnim =
        _slideAnimation ?? AlwaysStoppedAnimation<Offset>(Offset.zero);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: 'Factures',
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filtres',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              'Client',
                              Icons.person,
                              state.searchField == SearchField.client,
                              () => _changeSearchField(
                                SearchField.client,
                                notifier,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Statut paiement',
                              Icons.payment,
                              state.searchField == SearchField.paymentStatus,
                              () => _changeSearchField(
                                SearchField.paymentStatus,
                                notifier,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Période',
                              Icons.date_range,
                              state.searchField == SearchField.periode,
                              () => _changeSearchField(
                                SearchField.periode,
                                notifier,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchInterface(state.searchField, notifier),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune facture trouvée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) =>
                                _buildFactureCard(list[i], i),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeSearchField(SearchField field, FactureNotifier notifier) {
    _searchCtrl.clear();
    notifier.setQuery('');
    notifier.setPaymentStatusFilter('');
    notifier.setSearchField(field);
    if (field == SearchField.periode) _pickDateRange(context, notifier);
    setState(() {});
  }

  Widget _buildSearchInterface(SearchField field, FactureNotifier notifier) {
    switch (field) {
      case SearchField.paymentStatus:
        return DropdownButtonFormField<String>(
          value: notifier.state.paymentStatus.isEmpty
              ? 'Tous'
              : notifier.state.paymentStatus,
          items: <String>[
            'Tous',
            'en_attente',
            'partiellement_paye',
            'paye',
            'en_retard',
            'annule',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            notifier.setPaymentStatusFilter(
              (v == null || v == 'Tous') ? '' : v,
            );
          },
          decoration: const InputDecoration(
            labelText: 'Filtrer par statut paiement',
          ),
        );
      case SearchField.periode:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          icon: const Icon(Icons.date_range),
          label: Text(
            _range == null
                ? 'Sélectionner période'
                : '${DateFormat.yMd().format(_range!.start)} → ${DateFormat.yMd().format(_range!.end)}',
          ),
          onPressed: () => _pickDateRange(context, notifier),
        );
      case SearchField.client:
      return _buildTextField(
          _searchCtrl,
          'Rechercher par client (nom ou id)',
          Icons.search,
          onChanged: () {
            notifier.setQuery(_searchCtrl.text.trim());
          },
        );
    }
  }

  Future<void> _pickDateRange(
    BuildContext context,
    FactureNotifier notifier,
  ) async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _range = picked);
      notifier.setDateRange(picked.start, picked.end);
      notifier.setQuery('');
    }
  }
}
