import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/Facture/facture_screen.dart';
import 'package:garagelink/mecanicien/devis/devis_preview_page.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/historique_devis_provider.dart';

enum TypeFiltre { date, numeroSerie, id, client }

class HistoriqueDevisPage extends ConsumerStatefulWidget {
  const HistoriqueDevisPage({super.key});

  @override
  ConsumerState<HistoriqueDevisPage> createState() => _HistoriqueDevisPageState();
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

  final Map<TypeFiltre, Map<String, dynamic>> filtreConfig = {
    TypeFiltre.date: {'icon': Icons.calendar_today, 'label': 'Par date', 'color': Colors.orange},
    TypeFiltre.numeroSerie: {'icon': Icons.confirmation_number, 'label': 'Par numéro série', 'color': Colors.purple},
    TypeFiltre.id: {'icon': Icons.tag, 'label': 'Par ID devis', 'color': Colors.green},
    TypeFiltre.client: {'icon': Icons.person, 'label': 'Par client', 'color': Colors.blue},
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
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
        boxShadow: [BoxShadow(color: Color(0x20357ABD), blurRadius: 8, offset: Offset(0, 2))],
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
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
                    const Text('Historique des Devis', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Recherchez et consultez vos devis', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.filter_alt, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Filtres de recherche', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TypeFiltre>(
            value: typeFiltre,
            decoration: InputDecoration(
              labelText: 'Type de filtre',
              prefixIcon: Icon(filtreConfig[typeFiltre]!['icon'], color: primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: lightGrey,
            ),
            items: TypeFiltre.values.map((type) {
              final config = filtreConfig[type]!;
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(config['icon'], color: config['color'], size: 18),
                    const SizedBox(width: 8),
                    Text(config['label']),
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
              label: const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
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
              decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.date_range, color: primaryBlue, size: 20),
            ),
            title: Text(
              dateRange == null ? "Choisir une période" : "${dateRange!.start.toString().split(' ')[0]} → ${dateRange!.end.toString().split(' ')[0]}",
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
                  return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryBlue)), child: child!);
                },
              );
              if (picked != null) {
                setState(() {
                  dateRange = picked;
                  valeurFiltre = "${picked.start.toIso8601String()}|${picked.end.toIso8601String()}";
                });
              }
            },
          ),
        );
      case TypeFiltre.numeroSerie:
        return NumeroSerieInput(
          vinCtrl: vinCtrl,
          numLocalCtrl: numLocalCtrl,
          onChanged: (value) => valeurFiltre = value,
        );
      default:
        return TextField(
          controller: rechercheCtrl,
          decoration: InputDecoration(
            hintText: typeFiltre == TypeFiltre.id ? "Entrer l'ID du devis" : "Entrer le nom du client",
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(8)),
              child: Icon(typeFiltre == TypeFiltre.id ? Icons.tag : Icons.person, color: primaryBlue, size: 20),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: lightGrey,
          ),
          onChanged: (value) => valeurFiltre = value,
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
            decoration: BoxDecoration(color: lightBlue, shape: BoxShape.circle),
            child: const Icon(Icons.search_off, size: 48, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          const Text('Aucun devis trouvé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkGrey)),
          const SizedBox(height: 8),
          Text('Essayez de modifier vos critères de recherche',
              style: TextStyle(color: darkGrey.withOpacity(0.7))),
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

      // --- Gestion statut ---
      Color statusColor;
      String statusLabel;
      switch (devis.status) {
        case DevisStatus.brouillon:
          statusLabel = 'Brouillon';
          statusColor = Colors.grey;
          break;
        case DevisStatus.envoye:
        case DevisStatus.enAttente:
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
            )
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
            child: const Icon(Icons.description, color: primaryBlue, size: 24),
          ),
          title: Text(
            devis.client,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkGrey),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: darkGrey.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    devis.date.toLocal().toString().split(" ")[0],
                    style: TextStyle(color: darkGrey.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.euro, size: 14, color: darkGrey.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${devis.totalTtc.toStringAsFixed(2)}€',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: primaryBlue),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              if (devis.status == DevisStatus.brouillon ||
                  devis.status == DevisStatus.envoye ||
                  devis.status == DevisStatus.enAttente)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Accepter',
                      onPressed: () {
                        ref
                            .read(historiqueDevisProvider.notifier)
                            .updateStatusById(devis.id, DevisStatus.accepte);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Refuser',
                      onPressed: () {
                        ref
                            .read(historiqueDevisProvider.notifier)
                            .updateStatusById(devis.id, DevisStatus.refuse);
                      },
                    ),
                  ],
                ),
              if (devis.status == DevisStatus.accepte)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Générer facture'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FactureScreen(devis: devis)),
                    );
                  },
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DevisPreviewPage()),
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