import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class AddVehScreen extends ConsumerStatefulWidget {
  final String clientId;
  const AddVehScreen({required this.clientId, Key? key}) : super(key: key);

  @override
  ConsumerState<AddVehScreen> createState() => _AddVehScreenState();
}

class _AddVehScreenState extends ConsumerState<AddVehScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _vinCtrl = TextEditingController();
  final _numLocalCtrl = TextEditingController();
  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _annee = TextEditingController();
  final _km = TextEditingController();
  final _dateCtrl = TextEditingController();

late AnimationController _animationController;
Animation<double>? _fadeAnimation;
Animation<Offset>? _slideAnimation;

  DateTime? _dateCirculation;
  String? _picKmPath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  Carburant _selectedCarburant = Carburant.essence;

  // Palette de couleurs unifiée
  static const Color _primaryBlue = Color(0xFF357ABD);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _darkBlue = Color(0xFF1976D2);
  static const Color _errorRed = Color(0xFFD32F2F);
  static const Color _successGreen = Color(0xFF388E3C);
  static const Color _surfaceColor = Color(0xFFF8F9FA);
  static const Color _accentOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _vinCtrl.dispose();
    _numLocalCtrl.dispose();
    _marque.dispose();
    _modele.dispose();
    _annee.dispose();
    _km.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final initial = _dateCirculation ?? now;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
      helpText: 'Date de première circulation',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _dateCirculation = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String? _requiredValidator(String? v) =>
      v == null || v.trim().isEmpty ? 'Ce champ est obligatoire' : null;

  String? _yearValidator(String? v) {
    if (v == null || v.isEmpty) return null;
    final year = int.tryParse(v);
    if (year == null) return 'Année invalide';
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'Année entre 1900 et ${currentYear + 1}';
    }
    return null;
  }

  String? _kmValidator(String? v) {
    if (v == null || v.isEmpty) return null;
    final km = int.tryParse(v);
    if (km == null) return 'Kilométrage invalide';
    if (km < 0 || km > 999999) return 'Kilométrage entre 0 et 999 999 km';
    return null;
  }

  Future<void> _takePhoto() async {
    HapticFeedback.mediumImpact();
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _picKmPath = photo.path;
        });
        _showSuccessSnackBar('Photo du compteur capturée');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la capture: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _picKmPath = photo.path;
        });
        _showSuccessSnackBar('Photo sélectionnée');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection: ${e.toString()}');
    }
  }

  bool _validateImmatriculation() {
    final vin = _vinCtrl.text.trim();
    final local = _numLocalCtrl.text.trim();
    return vin.isNotEmpty || local.isNotEmpty;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    HapticFeedback.mediumImpact();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Veuillez corriger les erreurs du formulaire');
      return;
    }

    if (!_validateImmatriculation()) {
      _showErrorSnackBar('Veuillez saisir le numéro local ou le VIN');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final immat = _numLocalCtrl.text.trim().isNotEmpty
          ? _numLocalCtrl.text.trim()
          : _vinCtrl.text.trim();

      final vehicule = Vehicule(
        id: const Uuid().v4(),
        immatriculation: immat,
        marque: _marque.text.trim(),
        modele: _modele.text.trim(),
        carburant: _selectedCarburant,
        annee: int.tryParse(_annee.text.trim()),
        kilometrage: int.tryParse(_km.text.trim()),
        picKm: _picKmPath,
        dateCirculation: _dateCirculation,
        clientId: widget.clientId,
      );

       ref.read(vehiculesProvider.notifier).addVehicule(vehicule);
      
      HapticFeedback.heavyImpact();
      _showSuccessSnackBar('Véhicule ajouté avec succès!');
      
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? helperText,
    String? suffixText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          suffixText: suffixText,
          prefixIcon: Icon(icon, color: _primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _errorRed, width: 2),
          ),
          filled: true,
          fillColor: _surfaceColor,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCarburantSelector() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_gas_station, color: _primaryBlue),
                SizedBox(width: 12),
                Text(
                  'Type de carburant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: Carburant.values.map((carburant) {
                final isSelected = _selectedCarburant == carburant;
                final label = _getCarburantLabel(carburant);
                final icon = _getCarburantIcon(carburant);
                
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: isSelected ? _primaryBlue : Colors.grey),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCarburant = carburant);
                  },
                  selectedColor: _lightBlue,
                  checkmarkColor: _primaryBlue,
                  backgroundColor: Colors.grey.shade100,
                  elevation: isSelected ? 2 : 0,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getCarburantLabel(Carburant carburant) {
    switch (carburant) {
      case Carburant.essence:
        return 'Essence';
      case Carburant.diesel:
        return 'Diesel';
      case Carburant.gpl:
        return 'GPL';
      case Carburant.electrique:
        return 'Électrique';
      case Carburant.hybride:
        return 'Hybride';
      }
  }

  IconData _getCarburantIcon(Carburant carburant) {
    switch (carburant) {
      case Carburant.essence:
        return Icons.local_gas_station;
      case Carburant.diesel:
        return Icons.oil_barrel;
      case Carburant.gpl:
        return Icons.propane_tank;
      case Carburant.electrique:
        return Icons.electric_bolt;
      case Carburant.hybride:
        return Icons.battery_charging_full;
      }
  }

  Widget _buildPhotoSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.camera_alt, color: _primaryBlue),
                SizedBox(width: 12),
                Text(
                  'Photo du compteur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text('Optionnel', style: TextStyle(fontSize: 11)),
                  backgroundColor: Color(0xFFE8F5E8),
                  labelStyle: TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Appareil photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _takePhoto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: _primaryBlue),
                    ),
                    onPressed: _pickFromGallery,
                  ),
                ),
              ],
            ),
            if (_picKmPath != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Get.to(() => ImagePreviewScreen(imagePath: _picKmPath!));
                        },
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          child: Image.file(
                            File(_picKmPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => _picKmPath = null);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.touch_app, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Appuyer pour agrandir',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => _pickDate(context),
        child: AbsorbPointer(
          child: TextFormField(
            controller: _dateCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Date de première circulation',
              helperText: 'Date optionnelle de mise en service',
              prefixIcon: const Icon(Icons.calendar_today, color: _primaryBlue),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: _primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: _surfaceColor,
              labelStyle: TextStyle(color: Colors.grey.shade700),
              helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Ajouter le véhicule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
  title: 'Nouveau véhicule',
  backgroundColor: _primaryBlue, // ou primaryBlue si tu utilises ui_constants
),
     body: FadeTransition(
  // si _fadeAnimation est null, on utilise un AlwaysStoppedAnimation (opacité = 1.0)
  opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
  child: SlideTransition(
    // si _slideAnimation est null, on utilise une AlwaysStoppedAnimation pour Offset
    position: _slideAnimation ?? const AlwaysStoppedAnimation<Offset>(Offset.zero),
    child: SafeArea(
      child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section Identification
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.assignment, color: _primaryBlue),
                                SizedBox(width: 12),
                                Text(
                                  'Identification du véhicule',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            NumeroSerieInput(
                              vinCtrl: _vinCtrl,
                              numLocalCtrl: _numLocalCtrl,
                              onChanged: (v) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Informations techniques
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.build, color: _primaryBlue),
                                SizedBox(width: 12),
                                Text(
                                  'Informations techniques',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: _marque,
                              label: 'Marque',
                              icon: Icons.business,
                              validator: _requiredValidator,
                              helperText: 'Ex: Peugeot, Renault, Toyota...',
                            ),
                            _buildCustomTextField(
                              controller: _modele,
                              label: 'Modèle',
                              icon: Icons.directions_car,
                              validator: _requiredValidator,
                              helperText: 'Ex: 308, Clio, Corolla...',
                            ),
                            _buildCustomTextField(
                              controller: _annee,
                              label: 'Année de fabrication',
                              icon: Icons.calendar_today,
                              validator: _yearValidator,
                              keyboardType: TextInputType.number,
                              helperText: 'Année de première immatriculation',
                            ),
                            _buildCustomTextField(
                              controller: _km,
                              label: 'Kilométrage actuel',
                              icon: Icons.speed,
                              validator: _kmValidator,
                              keyboardType: TextInputType.number,
                              suffixText: 'km',
                              helperText: 'Kilométrage au compteur',
                            ),
                            _buildDateSelector(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Carburant
                    _buildCarburantSelector(),
                    const SizedBox(height: 20),

                    // Section Photo
                    _buildPhotoSection(),
                    const SizedBox(height: 32),

                    // Bouton de soumission
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Écran de prévisualisation d'image amélioré
class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  const ImagePreviewScreen({required this.imagePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Aperçu de la photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.back();
          },
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}