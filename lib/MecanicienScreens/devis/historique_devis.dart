import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/Facture/facture_detail_page.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/create_ordre_screen.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/ficheClient.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/providers/ficheClient_provider.dart';
import 'package:garagelink/providers/historique_devis_provider.dart';
import 'package:garagelink/services/facture_api.dart';
import 'package:garagelink/utils/devis_actions.dart';
import 'package:garagelink/services/devis_api.dart';
import 'package:get/get.dart';

enum TypeFiltre { date, numeroSerie, id, client }

class HistoriqueDevisPage extends ConsumerStatefulWidget {
  const HistoriqueDevisPage({super.key});

  @override
  ConsumerState<HistoriqueDevisPage> createState() =>
      _HistoriqueDevisPageState();
}

class _HistoriqueDevisPageState extends ConsumerState<HistoriqueDevisPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF357ABD);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkGrey = Color(0xFF2C3E50);
  static const Color lightGrey = Color(0xFFF8F9FA);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  TypeFiltre typeFiltre = TypeFiltre.client;
  DateTimeRange? dateRange;
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();
  final rechercheCtrl = TextEditingController();
  String valeurFiltre = "";

  String _devisIdToUse(Devis devis) {
    // Priorité à l'ID Mongo (_id) si présent (chaîne 24 hex ou simplement non vide côté client)
    if (devis.id != null && devis.id!.isNotEmpty) {
      return devis.id!;
    }
    // Sinon fallback sur le code personnalisé (DEVxxx)
    if (devis.devisId.isNotEmpty) {
      return devis.devisId;
    }
    // Aucun ID disponible
    return '';
  }

  final Map<TypeFiltre, Map<String, dynamic>> filtreConfig = {
    TypeFiltre.date: {
      'icon': Icons.calendar_today,
      'label': 'Par date',
      'color': Colors.orange,
    },
    TypeFiltre.numeroSerie: {
      'icon': Icons.confirmation_number,
      'label': 'Par numéro série',
      'color': Colors.purple,
    },
    TypeFiltre.id: {
      'icon': Icons.tag,
      'label': 'Par ID devis',
      'color': Colors.green,
    },
    TypeFiltre.client: {
      'icon': Icons.person,
      'label': 'Par client',
      'color': Colors.blue,
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // charger l'historique
      ref.read(historiqueDevisProvider.notifier).loadAll();

      // précharger explicitement la liste clients
      try {
        ref.read(ficheClientsProvider.notifier).loadNoms();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    vinCtrl.dispose();
    numLocalCtrl.dispose();
    rechercheCtrl.dispose();
    super.dispose();
  }

  Widget _buildModernAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x20357ABD),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historique des Devis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Recherchez et consultez vos devis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_alt,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filtres de recherche',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TypeFiltre>(
            value: typeFiltre,
            decoration: InputDecoration(
              labelText: 'Type de filtre',
              prefixIcon: Icon(
                filtreConfig[typeFiltre]!['icon'] as IconData,
                color: primaryBlue,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: lightGrey,
            ),
            items: TypeFiltre.values.map((type) {
              final config = filtreConfig[type]!;
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      config['icon'] as IconData,
                      color: config['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(config['label'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                HapticFeedback.selectionClick();
                setState(() {
                  typeFiltre = val;
                  valeurFiltre = "";
                  dateRange = null;
                  vinCtrl.clear();
                  numLocalCtrl.clear();
                  rechercheCtrl.clear();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildFilterInput(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'Rechercher',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Mettre à jour le provider de filtre (string)
                ref.read(filtreProvider.notifier).state = valeurFiltre;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterInput() {
    switch (typeFiltre) {
      case TypeFiltre.date:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: lightGrey,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.date_range, color: primaryBlue, size: 20),
            ),
            title: Text(
              dateRange == null
                  ? "Choisir une période"
                  : "${dateRange!.start.toString().split(' ')[0]} → ${dateRange!.end.toString().split(' ')[0]}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              HapticFeedback.lightImpact();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: primaryBlue),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  dateRange = picked;
                  valeurFiltre =
                      "${picked.start.toIso8601String()}|${picked.end.toIso8601String()}";
                });
              }
            },
          ),
        );
      case TypeFiltre.numeroSerie:
        return NumeroSerieInput(
          vinCtrl: vinCtrl,
          numLocalCtrl: numLocalCtrl,
          onChanged: (value) {
            setState(() {
              valeurFiltre = value;
            });
          },
        );
      default:
        return TextField(
          controller: rechercheCtrl,
          decoration: InputDecoration(
            hintText: typeFiltre == TypeFiltre.id
                ? "Entrer l'ID du devis"
                : "Entrer le nom du client",
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                typeFiltre == TypeFiltre.id ? Icons.tag : Icons.person,
                color: primaryBlue,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: lightGrey,
          ),
          onChanged: (value) {
            valeurFiltre = value;
          },
        );
    }
  }

  Widget _buildResultsList() {
    final historique = ref.watch(devisFiltresProvider);

    if (historique.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off, size: 48, color: primaryBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun devis trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(color: darkGrey.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: historique.length,
      itemBuilder: (context, index) {
        final devis = historique[index];

        // --- Gestion statut --- (labels unchanged)
        Color statusColor;
        String statusLabel;
        switch (devis.status) {
          case DevisStatus.brouillon:
            statusLabel = 'Brouillon';
            statusColor = Colors.grey;
            break;
          case DevisStatus.envoye:
            statusLabel = 'Envoyé';
            statusColor = Colors.orange;
            break;
          case DevisStatus.accepte:
            statusLabel = 'Accepté';
            statusColor = Colors.green;
            break;
          case DevisStatus.refuse:
            statusLabel = 'Refusé';
            statusColor = Colors.red;
            break;
        }

        // --- Date safe: inspectionDate is a String in your model ---
        DateTime? parsed;
        if (devis.inspectionDate.isNotEmpty) {
          try {
            parsed = DateTime.tryParse(devis.inspectionDate);
          } catch (_) {
            parsed = null;
          }
        }
        final DateTime displayDate =
            parsed ?? devis.createdAt ?? DateTime.now();
        final String dateStr = displayDate.toLocal().toString().split(" ")[0];

        // --- Montant safe ---
        final double montant = devis.totalTTC;

        // --- Construction dynamique des boutons d'actions (simplifié) ---
        final List<Widget> actionButtons = [];

        // Send / resend button available for brouillon & envoye (resend)
        if (devis.status == DevisStatus.brouillon ||
            devis.status == DevisStatus.envoye) {
          actionButtons.add(
            IconButton(
              icon: const Icon(Icons.send, color: Colors.orange, size: 18),
              tooltip: 'Envoyer par e-mail',
              onPressed: () async {
                // Récupérer l'email du client depuis le provider ficheClientsProvider
                String? clientEmail;
                final ficheState = ref.read(ficheClientsProvider);
                final clientsList = ficheState.clients;

                // essayer d'abord dans la liste locale (peut contenir seulement noms si loadNoms)
                final foundLocal = clientsList.firstWhere(
                  (c) => (c.id ?? '') == (devis.clientId),
                  orElse: () => FicheClient(
                    id: null,
                    nom: '',
                    type: ClientType.particulier,
                    adresse: '',
                    telephone: '',
                    email: '',
                  ),
                );
                if (foundLocal.email.trim().isNotEmpty) {
                  clientEmail = foundLocal.email.trim();
                } else {
                  // si pas d'email local, appeler l'API pour récupérer la fiche complète
                  try {
                    final fetched = await ref
                        .read(ficheClientsProvider.notifier)
                        .getById(devis.clientId);
                    if (fetched != null && fetched.email.trim().isNotEmpty) {
                      clientEmail = fetched.email.trim();
                      // opcional : mettre à jour la liste locale pour éviter de re-fetch
                      // tu peux créer un update dans le provider si tu veux (state = [..., fetched])
                    }
                  } catch (_) {
                    // ignore - on demandera à l'utilisateur si toujours pas d'email
                  }
                }

                // ID custom (DEVxxx) à utiliser pour l'endpoint send-email (ton backend cherche par { id: devisId })
                final String idToUse = _devisIdToUse(devis);
                print(
                  '➡️ sendDevis : idToUse=$idToUse (devis.id=${devis.id}, devis.devisId=${devis.devisId})',
                );

                // essayer envoi via backend si token présent
                final token = ref.read(authTokenProvider);
                if (token != null && token.isNotEmpty && idToUse.isNotEmpty) {
                  try {
                    await DevisApi.sendDevisByEmail(
                      token: token,
                      devisId: idToUse,
                    );
                    // Best-effort: mettre à jour localement le status en 'envoye'
                    try {
                      ref
                          .read(historiqueDevisProvider.notifier)
                          .updateStatusById(idToUse, DevisStatus.envoye);
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Devis envoyé par email (serveur)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    return;
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Envoi via serveur échoué : ${e.toString()} — utilisation du partage local',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    // fallback to local share below
                  }
                }

                // Si on n'a pas d'email connu, demander à l'utilisateur
                if (clientEmail == null || clientEmail.isEmpty) {
                  final typed = await showDialog<String?>(
                    context: context,
                    builder: (ctx) {
                      String temp = '';
                      return AlertDialog(
                        title: const Text('E-mail du client'),
                        content: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail du client',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) => temp = v,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, temp.trim()),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );

                  if (typed == null || typed.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Envoi annulé — aucun e-mail fourni'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  clientEmail = typed;
                }

                // fallback local : ouvrir compose mail (mailto) ou partager le PDF
                await generateAndSendDevis(
                  ref,
                  context,
                  devisToSend: devis,
                  recipientEmail: clientEmail,
                );
              },
            ),
          );
        }

        // For accepted: show receipt/download and preview
        // For accepted: show "facture" + "create order"
        if (devis.status == DevisStatus.accepte) {
          actionButtons.addAll([
            IconButton(
              icon: const Icon(
                Icons.receipt_long,
                color: Colors.blue,
                size: 18,
              ),
              tooltip: 'Générer la facture',
              onPressed: () async {
                final String idToUse = _devisIdToUse(devis);
                print(
                  '➡️ createFacture: will use idToUse=$idToUse (devis.id=${devis.id}, devis.devisId=${devis.devisId})',
                );
                final token = ref.read(authTokenProvider);
                if (token == null || token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vous devez être connecté pour générer une facture',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (idToUse.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID du devis manquant'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Affiche un loader modal
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Appel API pour créer la facture côté serveur
                  final Facture created = await FactureApi.createFacture(
                    token: token,
                    devisId: idToUse,
                  );

                  // Optionnel : ajouter dans le provider local si tu veux
                  try {
                    // si tu as facturesProvider avec ajouter/ajouterFacture méthode : appelle-la
                    // ex: ref.read(facturesProvider.notifier).ajouterFactureFromObject(created);
                    // Ici j'appelle ajouterFacture qui utilise createFacture interne, donc on évite double call.
                  } catch (_) {}

                  // Ferme le loader modal
                  Navigator.of(context).pop();

                  // Navigue vers la page détail facture
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FactureDetailPage(facture: created),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Facture créée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Ferme le loader modal en cas d'erreur
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur création facture : ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.playlist_add_check_circle,
                color: Colors.green,
                size: 20,
              ),
              tooltip: 'Créer un ordre',
              onPressed: () {
                Get.to(
                  () => CreateOrderScreen(
                    devis: devis,
                    // si tu veux encore utiliser Get.arguments pour vehicleInfo, tu peux aussi ajouter params au constructeur
                  ),
                  arguments: {
                    'vehiculeId': devis.vehiculeId,
                    'vehicleInfo': devis.vehicleInfo,
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.visibility, color: primaryBlue, size: 18),
              tooltip: 'Voir la facture',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevisPreviewPage(devis: devis),
                  ),
                );
              },
            ),
          ]);
        } else {
          // For other statuses (brouillon/envoye) also allow preview
          actionButtons.add(
            IconButton(
              icon: const Icon(Icons.visibility, color: primaryBlue, size: 18),
              tooltip: 'Voir le devis',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevisPreviewPage(devis: devis),
                  ),
                );
              },
            ),
          );
        }

        // --- UI ---
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description,
                color: primaryBlue,
                size: 24,
              ),
            ),
            // ⇢ Affiche l'ID du devis comme titre (DEVxxx) — demandé
            title: Text(
              (devis.devisId.isNotEmpty)
                  ? devis.devisId
                  : (devis.id?.isNotEmpty == true
                        ? devis.id!
                        : 'Devis sans ID'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: darkGrey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: TextStyle(color: darkGrey.withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        devis.clientName.isNotEmpty
                            ? devis.clientName
                            : 'Client non spécifié',
                        style: TextStyle(color: darkGrey.withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.money,
                      size: 14,
                      color: darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${montant.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: SizedBox(
              width: 160,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actionButtons,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DevisPreviewPage(devis: devis),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildModernAppBar(),
            _buildFilterCard(),
            Expanded(child: _buildResultsList()),
          ],
        ),
      ),
    );
  }
}
