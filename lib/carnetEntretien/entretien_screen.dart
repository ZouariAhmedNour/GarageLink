// lib/mecanicien/intervention/intervention_screen.dart
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

  const EntretienScreen({
    required this.vehiculeId,
    this.initial,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EntretienScreen> createState() => _EntretienScreenState();
}

class _EntretienScreenState extends ConsumerState<EntretienScreen>
    with TickerProviderStateMixin {
  late TextEditingController _tacheCtrl;
  late TextEditingController _coutCtrl;
  late TextEditingController _serviceCtrl;
  late TextEditingController _kmCtrl;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  

  // Palette de couleurs unifiée
  static const Color primaryBlue = Color(0xFF357ABD);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color errorRed = Color(0xFFE53E3E);
  static const Color successGreen = Color(0xFF38A169);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
  }

  void _initializeControllers() {
    final init = widget.initial;
    _tacheCtrl = TextEditingController(text: init?.tache ?? '');
    _coutCtrl = TextEditingController(
        text: init != null ? init.coutTotal.toStringAsFixed(2) : '');
    _serviceCtrl = TextEditingController(text: init?.service ?? 'Entretien général');
    _date = init?.dateOperation ?? DateTime.now();
    _kmCtrl = TextEditingController(
  text: init?.kilometrage?.toString() ?? ''
);
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
    _tacheCtrl.dispose();
    _coutCtrl.dispose();
    _serviceCtrl.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _kmCtrl.dispose();

    super.dispose();
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
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
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

    if (_tacheCtrl.text.trim().isEmpty) {
      _showError('Veuillez saisir la description de la tâche');
      return false;
    }

    if (_serviceCtrl.text.trim().isEmpty) {
      _showError('Veuillez préciser le type de service');
      return false;
    }

    final cout = _parseDouble(_coutCtrl.text);
    if (cout != null && cout < 0) {
      _showError('Le coût ne peut pas être négatif');
      return false;
    }

    return true;
  }

  Future<void> _save() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simule le traitement

      final tache = _tacheCtrl.text.trim();
      final cout = _parseDouble(_coutCtrl.text) ?? 0.0;
      final service = _serviceCtrl.text.trim();

      final entry = (widget.initial != null)
          ? widget.initial!.copyWith(
              dateOperation: _date,
              service: service,
              tache: tache,
              coutTotal: cout)
          : CarnetEntretien(
              dateOperation: _date,
              service: service,
              tache: tache,
              coutTotal: cout);

      final notifier = ref.read(carnetProvider.notifier);
      if (widget.initial != null) {
        notifier.updateEntry(widget.vehiculeId, entry.idOperation, entry);
        _showSuccess('Intervention modifiée avec succès');
      } else {
        notifier.addEntry(widget.vehiculeId, entry);
        _showSuccess('Intervention ajoutée avec succès');
      }

      await Future.delayed(const Duration(milliseconds: 500));
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
        icon: const Icon(Icons.warning_amber_rounded, color: errorRed, size: 32),
        title: const Text('Supprimer l\'intervention ?'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        ref.read(carnetProvider.notifier)
            .removeEntry(widget.vehiculeId, widget.initial!.idOperation);
        _showSuccess('Intervention supprimée');
        Navigator.of(context).pop();
      } catch (e) {
        _showError('Erreur lors de la suppression');
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryBlue,
            ),
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
                child: const Icon(Icons.calendar_today, color: primaryBlue, size: 24),
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

  Widget _buildInputCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffix,
  }) {
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
                  child: Icon(icon, color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                suffixText: suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryBlue, width: 2),
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
  title: isEditing ? 'Modifier intervention' : 'Nouvelle intervention',
  showDelete: isEditing,
  onDelete: _delete, // ton callback
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
                const SizedBox(height: 20),
                _buildInputCard(
                 title: 'Kilométrage',
                 controller: _kmCtrl,
                 icon: Icons.speed,
                 hint: 'Ex: 120000',
                 keyboardType: TextInputType.number,
                 suffix: 'km',
               ),
               const SizedBox(height: 20),
                 _buildInputCard(
                  title: 'Type de service',
                  controller: _serviceCtrl,
                  icon: Icons.build_circle_outlined,
                  hint: 'Ex: Vidange, Révision, Réparation...',
                ),
                const SizedBox(height: 20),

                _buildInputCard(
                  title: 'Description de l\'intervention',
                  controller: _tacheCtrl,
                  icon: Icons.description_outlined,
                  hint: 'Décrivez les travaux effectués...',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                _buildInputCard(
                  title: 'Coût total',
                  controller: _coutCtrl,
                  icon: Icons.monetization_on_outlined,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'DT',
                ),
                const SizedBox(height: 32),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                                isEditing ? 'Enregistrer' : 'Ajouter',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}