import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:garagelink/providers/carnetEntretien_provider.dart';
import 'package:intl/intl.dart';

class EntretienScreen extends ConsumerStatefulWidget {
  final String vehiculeId;
  final CarnetEntretien? initial;

  const EntretienScreen({required this.vehiculeId, this.initial, Key? key})
    : super(key: key);

  @override
  ConsumerState<EntretienScreen> createState() => _EntretienScreenState();
}

class _EntretienScreenState extends ConsumerState<EntretienScreen>
    with TickerProviderStateMixin {
  // contrôleurs globaux (pour certains champs)
  late TextEditingController _kmCtrl;
  late TextEditingController _serviceGlobalCtrl; // si tu veux un label global
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  DateTime _date = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  // dynamic rows
  final List<_ServiceRow> _rows = [];

  // Palette de couleurs unifiée (identique à ton UI)
  static const Color primaryBlue = Color(0xFF357ABD);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color errorRed = Color(0xFFE53E3E);
  static const Color successGreen = Color(0xFF38A169);

  @override
  void initState() {
    super.initState();
    _initFromInitial();
    _setupAnimations();
  }

  void _initFromInitial() {
    final init = widget.initial;
    _kmCtrl = TextEditingController(
      text: init?.kilometrageEntretien?.toString() ?? '',
    );
    _serviceGlobalCtrl = TextEditingController(
      text: init?.services.isNotEmpty == true
          ? init!.services.first.description ?? ''
          : 'Entretien général',
    );
    _date = init?.dateCommencement ?? DateTime.now();

    // Préparer les lignes : si initial != null et a des services, mapper, sinon une ligne vide
    if (init != null && init.services.isNotEmpty) {
      for (final s in init.services) {
        final row = _ServiceRow.fromServiceEntretien(
          s,
          onChange: _recomputeTotal,
        );
        _rows.add(row);
      }
    } else {
      _rows.add(_ServiceRow.empty(onChange: _recomputeTotal));
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    _kmCtrl.dispose();
    _serviceGlobalCtrl.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  double _recomputeTotal() {
    double total = 0.0;
    for (final r in _rows) {
      final price = r.parsePrice() ?? 0.0;
      total += price; // quantité implicite = 1
    }
    setState(() {}); // pour rafraîchir l'affichage du total si besoin
    return total;
  }

  double get _computedTotal => _recomputeTotal();

  int? _parseInt(String s) {
    final cleaned = s.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  double? _parseDouble(String s) {
    final cleaned = s.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _validateInputs() {
    setState(() => _errorMessage = null);

    // au moins une tâche non vide
    final validRows = _rows
        .where((r) => r.nomCtrl.text.trim().isNotEmpty)
        .toList();
    if (validRows.isEmpty) {
      _showError(
        'Veuillez ajouter au moins une tâche/service avec une description',
      );
      return false;
    }

    // vérifier prix
    for (final r in validRows) {
      final price = r.parsePrice();
      if (r.priceCtrl.text.trim().isNotEmpty && price == null) {
        _showError('Prix invalide sur une ligne');
        return false;
      }
    }

    // kilométrage si renseigné
    if (_kmCtrl.text.trim().isNotEmpty && _parseInt(_kmCtrl.text) == null) {
      _showError('Kilométrage invalide');
      return false;
    }

    return true;
  }

    Future<void> _save() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final taches = <ServiceEntretien>[];
      for (final r in _rows) {
        if (r.nomCtrl.text.trim().isEmpty) continue; // ignorer lignes vides
        final nom = r.nomCtrl.text.trim();
        final desc = r.descCtrl.text.trim().isEmpty
            ? null
            : r.descCtrl.text.trim();
        final price = r.parsePrice();

        taches.add(
          ServiceEntretien(
            nom: nom,
            description: desc,
            quantite: 1, // quantité implicite
            prix: price,
          ),
        );
      }

      final cout = _computedTotal;

      final notifier = ref.read(carnetProvider.notifier);

      if (widget.initial == null) {
        // Création dynamique — on récupère l'objet retourné du provider
        final created = await notifier.ajouterEntree(
          vehiculeId: widget.vehiculeId,
          date: _date,
          taches: taches,
          cout: cout,
          notes:
              '${_serviceGlobalCtrl.text.isNotEmpty ? "${_serviceGlobalCtrl.text} — " : ""}${taches.isNotEmpty ? taches.first.nom : ''}',
        );
        _showSuccess('Intervention ajoutée avec succès');
      } else {
        // EDITION COMPLÈTE : on utilise updateEntry pour appliquer les changements (et marquer terminé si nécessaire)
        final carnetId = widget.initial!.id;
        if (carnetId == null) {
          _showError('Impossible de modifier : identifiant introuvable');
        } else {
          final km = _parseInt(_kmCtrl.text);

          // Construire la map d'updates : n'inclure que les champs non-null
          final updates = {
            'dateCommencement': _date.toIso8601String(),
            // on pose dateFinCompletion pour marquer terminé (conserve le comportement "Marquer terminé")
            'dateFinCompletion': _date.toIso8601String(),
            'kilometrageEntretien': km,
            'notes': '${_serviceGlobalCtrl.text.isNotEmpty ? "${_serviceGlobalCtrl.text} — " : ""}${taches.isNotEmpty ? taches.first.nom : ''}',
            'taches': taches.map((t) => t.toJson()).toList(),
            'totalTTC': cout,
          }..removeWhere((k, v) => v == null);

          // debug
          print('DEBUG: updateEntry body => ${updates}');

          try {
            await notifier.updateEntry(
              vehiculeId: widget.vehiculeId,
              carnetId: carnetId,
              updates: updates,
            );
            _showSuccess('Intervention mise à jour et marquée comme terminée');
          } catch (e) {
            _showError('Erreur lors de la mise à jour: ${e.toString()}');
            rethrow;
          }
        }
      }

      // retour après courte pause UX
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _delete() async {
    if (widget.initial == null) return;

    HapticFeedback.heavyImpact();

    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: errorRed,
          size: 32,
        ),
        title: const Text('Supprimer l\'intervention ?'),
        content: const Text(
          'Cette action est irréversible. L\'intervention sera définitivement supprimée.',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (conf == true) {
      final carnetId = widget.initial!.id;
      if (carnetId == null) {
        _showError('Identifiant de l\'intervention manquant');
        return;
      }

      try {
        setState(() => _isLoading = true);
        print('DEBUG: suppression demande pour carnetId=$carnetId vehiculeId=${widget.vehiculeId}');
        await ref
            .read(carnetProvider.notifier)
            
            .supprimerEntree(widget.vehiculeId, carnetId);
            print('DEBUG: suppression terminée (retour)');
        _showSuccess('Intervention supprimée');
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        _showError('Erreur lors de la suppression: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _date = picked);
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildDateCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: primaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date d\'intervention',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy', 'fr_FR').format(_date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineControls() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: primaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tâches / Services',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(
                            () => _rows.add(
                              _ServiceRow.empty(onChange: _recomputeTotal),
                            ),
                          );
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une ligne'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // list of rows
            Column(
              children: List.generate(_rows.length, (index) {
                final r = _rows[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: r.nomCtrl,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (_) => _recomputeTotal(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: r.priceCtrl,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Prix',
                            suffixText: 'DT',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _recomputeTotal(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  r.dispose();
                                  _rows.removeAt(index);
                                });
                                _recomputeTotal();
                              },
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmAndServiceCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: primaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: const Icon(Icons.speed, color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kilométrage',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _kmCtrl,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 120000',
                      suffixText: 'km',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serviceGlobalCtrl,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Type de service (libellé général)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: isEditing ? 'Détails intervention' : 'Nouvelle intervention',
        showDelete: isEditing,
        onDelete: _delete,
        backgroundColor: primaryBlue,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateCard(),
                const SizedBox(height: 16),
                _buildKmAndServiceCard(),
                const SizedBox(height: 16),
                _buildLineControls(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Marquer terminé' : 'Ajouter',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isEditing)
                  Text(
                    'Note: l\'édition complète des champs d\'une entrée existante n\'est pas implémentée. Le bouton "Marquer terminé" mettra l\'entrée à jour comme complétée.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper interne : représente une ligne de service avec ses controllers
class _ServiceRow {
  final TextEditingController nomCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final VoidCallback? onChange;

  _ServiceRow({
    required this.nomCtrl,
    required this.descCtrl,
    required this.priceCtrl,
    this.onChange,
  }) {
    nomCtrl.addListener(_onChanged);
    descCtrl.addListener(_onChanged);
    priceCtrl.addListener(_onChanged);
  }

  factory _ServiceRow.empty({VoidCallback? onChange}) {
    return _ServiceRow(
      nomCtrl: TextEditingController(),
      descCtrl: TextEditingController(),
      priceCtrl: TextEditingController(),
      onChange: onChange,
    );
  }

  factory _ServiceRow.fromServiceEntretien(
    ServiceEntretien s, {
    VoidCallback? onChange,
  }) {
    return _ServiceRow(
      nomCtrl: TextEditingController(text: s.nom),
      descCtrl: TextEditingController(text: s.description ?? ''),
      priceCtrl: TextEditingController(text: s.prix?.toStringAsFixed(2) ?? ''),
      onChange: onChange,
    );
  }

  void _onChanged() {
    if (onChange != null) onChange!();
  }

  double? parsePrice() {
    try {
      final t = priceCtrl.text.replaceAll(',', '.').trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    } catch (_) {
      return null;
    }
  }

  ServiceEntretien toServiceEntretien() {
    return ServiceEntretien(
      nom: nomCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      quantite: 1,
      prix: parsePrice(),
    );
  }

  void dispose() {
    nomCtrl.removeListener(_onChanged);
    descCtrl.removeListener(_onChanged);
    priceCtrl.removeListener(_onChanged);
    nomCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
  }
}
