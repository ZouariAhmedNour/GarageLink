import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:garagelink/vehicules/car%20widgets/history_and_carnet_section.dart';
import 'package:garagelink/vehicules/car%20widgets/info_row.dart';
import 'package:garagelink/vehicules/car%20widgets/photo_section.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:garagelink/vehicules/car%20widgets/vehicle_header.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class VehiculeInfoScreen extends ConsumerStatefulWidget {
  final String vehiculeId;
  const VehiculeInfoScreen({required this.vehiculeId, Key? key})
    : super(key: key);

  @override
  ConsumerState<VehiculeInfoScreen> createState() => _VehiculeInfoScreenState();
}

class _VehiculeInfoScreenState extends ConsumerState<VehiculeInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // confirmDelete : capture notifier avant d'effectuer des opérations qui peuvent déclencher des rebuilds
  void _confirmDelete(BuildContext context, WidgetRef ref, Vehicule veh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: errorRed),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le véhicule ${veh.marque} ${veh.modele} (${veh.immatriculation}) ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(ctx).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              if (veh.id == null || veh.id!.isEmpty) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID véhicule manquant'),
                      backgroundColor: errorRed,
                    ),
                  );
                }
                return;
              }

              final notifier = ref.read(vehiculesProvider.notifier);
              Navigator.of(ctx).pop();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Suppression en cours...')),
                );
              }

              try {
                await notifier.removeVehicule(veh.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Véhicule supprimé avec succès'),
                      backgroundColor: successGreen,
                    ),
                  );
                  Get.back();
                }
              } catch (e) {
                // tentative de refresh
                try {
                  if (veh.proprietaireId != null &&
                      veh.proprietaireId!.isNotEmpty) {
                    await notifier.loadByProprietaire(veh.proprietaireId!);
                  } else {
                    await notifier.loadAll();
                  }
                } catch (_) {}
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur réseau: $e'),
                      backgroundColor: errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehState = ref.watch(vehiculesProvider);

    Vehicule? veh;
    try {
      veh = vehState.vehicules.firstWhere((v) => v.id == widget.vehiculeId);
    } catch (e) {
      veh = null;
    }

    if (veh == null) {
      return Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Véhicule non trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                iconTheme: const IconThemeData(color: Colors.white),
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                toolbarTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.back();
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      // open sheet — la fonction capture le notifier si nécessaire
                      await openEditVehicleSheet(context, ref, veh!);
                    },
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _confirmDelete(context, ref, veh!);
                    },
                    tooltip: 'Supprimer',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${veh.marque} ${veh.modele}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryBlue, darkBlue],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      VehicleHeader(veh: veh),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.info,
                                    color: primaryBlue,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Informations détaillées',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: darkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              InfoRow(
                                label: 'Immatriculation',
                                value: veh.immatriculation,
                                icon: Icons.confirmation_number,
                              ),
                              InfoRow(
                                label: 'Marque',
                                value: veh.marque,
                                icon: Icons.business,
                              ),
                              InfoRow(
                                label: 'Modèle',
                                value: veh.modele,
                                icon: Icons.directions_car,
                              ),
                              InfoRow(
                                label: 'Carburant',
                                value: fuelTypeLabel(veh.typeCarburant),
                                icon: fuelTypeIcon(veh.typeCarburant),
                              ),
                              InfoRow(
                                label: 'Année de fabrication',
                                value: veh.annee?.toString() ?? '-',
                                icon: Icons.calendar_today,
                              ),
                              InfoRow(
                                label: 'Kilométrage',
                                value: veh.kilometrage != null
                                    ? '${veh.kilometrage!.toString()} km'
                                    : '-',
                                icon: Icons.speed,
                                valueColor: accentOrange,
                              ),
                              InfoRow(
                                label: 'Créé le',
                                value: formatDate(veh.createdAt),
                                icon: Icons.event,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PhotoSection(veh: veh),
                      const SizedBox(height: 20),
                      HistoryCarnetSection(veh: veh),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre une bottom sheet pour éditer le véhicule.
/// NOTE: snapshot des valeurs + pop BEFORE any async network call to avoid "controller used after disposed".
Future<void> openEditVehicleSheet(
  BuildContext context,
  WidgetRef ref,
  Vehicule veh,
) {
  final picker = ImagePicker();

  // controllers (local scope)
  final _marqueCtrl = TextEditingController(text: veh.marque);
  final _modeleCtrl = TextEditingController(text: veh.modele);
  final _anneeCtrl = TextEditingController(text: veh.annee?.toString() ?? '');
  final _kmCtrl = TextEditingController(
    text: veh.kilometrage?.toString() ?? '',
  );
  String? _localPicPath = veh.picKm;
  final List<String> _localImages = List.from(veh.images);
  FuelType _selectedFuelType = veh.typeCarburant;
  final _formKey = GlobalKey<FormState>();

  // capture notifier dès maintenant pour l'utiliser après la fermeture de la sheet
  final vehNotifier = ref.read(vehiculesProvider.notifier);

  final future = showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder:
            (
              BuildContext innerContext,
              void Function(void Function()) setState,
            ) {
              String? _requiredValidator(String? v) =>
                  v == null || v.trim().isEmpty
                  ? 'Ce champ est obligatoire'
                  : null;

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
                if (km < 0 || km > 999999)
                  return 'Kilométrage entre 0 et 999 999 km';
                return null;
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // handle bar
                        Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // header
                        Row(
                          children: const [
                            Icon(Icons.edit, color: primaryBlue),
                            SizedBox(width: 12),
                            Text(
                              'Modifier le véhicule',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildEditTextField(
                                _marqueCtrl,
                                'Marque',
                                Icons.business,
                                validator: _requiredValidator,
                              ),
                              _buildEditTextField(
                                _modeleCtrl,
                                'Modèle',
                                Icons.directions_car,
                                validator: _requiredValidator,
                              ),
                              _buildEditTextField(
                                _anneeCtrl,
                                'Année',
                                Icons.calendar_today,
                                keyboardType: TextInputType.number,
                                validator: _yearValidator,
                              ),
                              _buildEditTextField(
                                _kmCtrl,
                                'Kilométrage',
                                Icons.speed,
                                keyboardType: TextInputType.number,
                                validator: _kmValidator,
                              ),

                              // carburant
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.local_gas_station,
                                          color: primaryBlue,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Carburant',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: FuelType.values.map((fuelType) {
                                        final isSelected =
                                            _selectedFuelType == fuelType;
                                        return FilterChip(
                                          label: Text(fuelTypeLabel(fuelType)),
                                          selected: isSelected,
                                          onSelected: (selected) => setState(
                                            () => _selectedFuelType = fuelType,
                                          ),
                                          selectedColor: lightBlue,
                                          checkmarkColor: primaryBlue,
                                          backgroundColor: Colors.grey.shade100,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),

                              // photo principale
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Photo principale'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final XFile? photo = await picker
                                              .pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1600,
                                                imageQuality: 80,
                                              );
                                          if (photo != null)
                                            setState(
                                              () => _localPicPath = photo.path,
                                            );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            innerContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Erreur photo: $e'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // preview photo principale
                              if (_localPicPath != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _localPicPath!.startsWith('http')
                                        ? Image.network(
                                            _localPicPath!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_localPicPath!),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ],

                              // ajouter photos
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('Ajouter photos'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final List<XFile>? photos =
                                              await picker.pickMultiImage(
                                                maxWidth: 1600,
                                                imageQuality: 80,
                                              );
                                          if (photos != null &&
                                              photos.isNotEmpty)
                                            setState(
                                              () => _localImages.addAll(
                                                photos.map((p) => p.path),
                                              ),
                                            );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            innerContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Erreur photos: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // preview images
                              if (_localImages.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _localImages.length,
                                    itemBuilder: (context, index) {
                                      final imagePath = _localImages[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 120,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child:
                                                    imagePath.startsWith('http')
                                                    ? Image.network(
                                                        imagePath,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(imagePath),
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => setState(
                                                  () => _localImages.removeAt(
                                                    index,
                                                  ),
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(innerContext).pop(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey.shade600,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Annuler'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (!(_formKey.currentState
                                                ?.validate() ??
                                            false)) {
                                          ScaffoldMessenger.of(
                                            innerContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Veuillez corriger les erreurs',
                                              ),
                                              backgroundColor: errorRed,
                                            ),
                                          );
                                          return;
                                        }
                                        if (veh.id == null || veh.id!.isEmpty) {
                                          ScaffoldMessenger.of(
                                            innerContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'ID véhicule manquant',
                                              ),
                                              backgroundColor: errorRed,
                                            ),
                                          );
                                          return;
                                        }

                                        // --- SNAPSHOT des valeurs ---
                                        final String newMarque = _marqueCtrl
                                            .text
                                            .trim();
                                        final String newModele = _modeleCtrl
                                            .text
                                            .trim();
                                        final int? newAnnee = int.tryParse(
                                          _anneeCtrl.text.trim(),
                                        );
                                        final int? newKm = int.tryParse(
                                          _kmCtrl.text.trim(),
                                        );
                                        final FuelType newFuel =
                                            _selectedFuelType;
                                        final String? newPic = _localPicPath;
                                        final List<String> newImages =
                                            List<String>.from(_localImages);

                                        // Fermer la sheet immédiatement -> libère les controllers
                                        Navigator.of(innerContext).pop();

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Enregistrement en cours...',
                                              ),
                                            ),
                                          );
                                        }

                                        try {
                                          await vehNotifier.updateVehicule(
                                            id: veh.id!,
                                            marque: newMarque,
                                            modele: newModele,
                                            typeCarburant: newFuel,
                                            annee: newAnnee,
                                            kilometrage: newKm,
                                            picKm: newPic,
                                            images: newImages,
                                          );

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Véhicule modifié avec succès',
                                                ),
                                                backgroundColor: successGreen,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Erreur: $e'),
                                                backgroundColor: errorRed,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Enregistrer'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
      );
    },
  );

  
  return future;
}

Widget _buildEditTextField(
  TextEditingController controller,
  String label,
  IconData icon, {
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        filled: true,
        fillColor: surfaceColor,
      ),
    ),
  );
}
