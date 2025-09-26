import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/user.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:garagelink/utils/devis_actions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PreviewColors {
  static const Color primary = Color(0xFF357ABD);
  static const Color primaryDark = Color(0xFF2A5F8F);
  static const Color secondary = Color(0xFF4A90E2);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color surface = Color(0xFFFAFAFA);
}

/// Page polymorphe capable d'afficher un Devis OU une Facture.
class DevisPreviewPage extends ConsumerStatefulWidget {
  final Devis? devis;
  final Facture? facture;

  const DevisPreviewPage({super.key, this.devis, this.facture});

  @override
  ConsumerState<DevisPreviewPage> createState() => _DevisPreviewPageState();
}

class _DevisPreviewPageState extends ConsumerState<DevisPreviewPage>
    with TickerProviderStateMixin {
  final GlobalKey _previewKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _capturePreviewPng() async {
    try {
      final context = _previewKey.currentContext;
      if (context == null) return null;
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Erreur capture PNG: $e");
      return null;
    }
  }

  /// Helper pour extraire un User? d'un watch/read dynamique (gère AsyncValue ou User direct).
  User? _extractUserFrom(dynamic maybeAsync) {
    try {
      if (maybeAsync is AsyncValue) {
        return maybeAsync.asData?.value;
      } else if (maybeAsync is User) {
        return maybeAsync;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Unified action handler that supports Devis OR Facture.
  Future<void> _handleAction(String action, {required Object doc}) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = _getProcessingMessage(action);
    });

    HapticFeedback.mediumImpact();

    final bool isFacture = doc is Facture;
    final bool isDevis = doc is Devis;

    try {
      switch (action) {
        case 'send':
          final png = await _capturePreviewPng();

          if (isDevis) {
            final Devis devis = doc;

            try {
              if (png != null) {
                await generateAndSendDevis(
                  ref,
                  context,
                  previewPng: png,
                  devisToSend: devis,
                );
              } else {
                await generateAndSendDevis(ref, context, devisToSend: devis);
              }
              _showSuccessMessage('Devis envoyé avec succès');
              break;
            } catch (e) {
              debugPrint('Envoi Devis avec preview échoué: $e — fallback share PDF');

              // try to get user (read provider)
              final dynUser = ref.read(currentUserProvider);
              final User? user = _extractUserFrom(dynUser);

              if (user == null) {
                _showErrorMessage('Impossible de récupérer les infos du garage pour générer le PDF.');
                break;
              }

              final bytes = await PdfService.instance.buildDevisPdfBytes(devis, user, footerNote: 'Généré par GarageLink');
              await Printing.sharePdf(bytes: bytes, filename: 'devis_${devis.id ?? 'doc'}.pdf');
              _showSuccessMessage('Devis partagé localement (fallback)');
              break;
            }
          }

          if (isFacture) {
            final Facture facture = doc;
            final bytes = await PdfService.instance.buildFacturePdfBytes(facture, footerNote: 'Généré par GarageLink');
            await Printing.sharePdf(bytes: bytes, filename: 'facture_${facture.numeroFacture}.pdf');
            _showSuccessMessage('Facture partagée (PDF)');
            break;
          }

          _showErrorMessage('Document inconnu pour envoi');
          break;

        case 'download':
          if (isDevis) {
            final Devis devis = doc;

            // get user to build PDF
            final dynUser = ref.read(currentUserProvider);
            final User? user = _extractUserFrom(dynUser);

            if (user == null) {
              _showErrorMessage('Impossible de récupérer les infos du garage pour générer le PDF.');
              break;
            }

            final bytes = await PdfService.instance.buildDevisPdfBytes(devis, user, footerNote: 'Généré par GarageLink');

            if (kIsWeb) {
              await Printing.sharePdf(bytes: bytes, filename: 'devis_${(devis.clientName).replaceAll(RegExp(r"[^A-Za-z0-9_]"), "_")}.pdf');
              _showSuccessMessage('PDF prêt à être téléchargé (web).');
              break;
            }

            Directory? targetDir;
            try {
              targetDir = await getDownloadsDirectory();
            } catch (_) {
              targetDir = null;
            }
            targetDir ??= await getApplicationDocumentsDirectory();

            final safeClient = (devis.clientName.isNotEmpty ? devis.clientName : 'client')
                .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
            final fileName = 'devis_${safeClient}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final filePath = '${targetDir.path}/$fileName';

            try {
              final file = File(filePath);
              await file.writeAsBytes(bytes, flush: true);
              _showSuccessMessage('PDF enregistré :\n$filePath');
            } catch (e) {
              debugPrint('Erreur écriture fichier PDF: $e');
              await Printing.sharePdf(bytes: bytes, filename: fileName);
              _showSuccessMessage('Impossible d\'écrire localement, PDF partagé.');
            }
            break;
          }

          if (isFacture) {
            final Facture facture = doc;
            final bytes = await PdfService.instance.buildFacturePdfBytes(facture, footerNote: 'Généré par GarageLink');

            if (kIsWeb) {
              await Printing.sharePdf(bytes: bytes, filename: 'facture_${(facture.clientInfo.nom ?? 'client').replaceAll(RegExp(r"[^A-Za-z0-9_]"), "_")}.pdf');
              _showSuccessMessage('PDF prêt à être téléchargé (web).');
              break;
            }

            Directory? targetDir;
            try {
              targetDir = await getDownloadsDirectory();
            } catch (_) {
              targetDir = null;
            }
            targetDir ??= await getApplicationDocumentsDirectory();

            final safeClient = ((facture.clientInfo.nom?.isNotEmpty ?? false) ? facture.clientInfo.nom! : 'client')
                .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
            final fileName = 'facture_${safeClient}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final filePath = '${targetDir.path}/$fileName';

            try {
              final file = File(filePath);
              await file.writeAsBytes(bytes, flush: true);
              _showSuccessMessage('PDF enregistré :\n$filePath');
            } catch (e) {
              debugPrint('Erreur écriture fichier PDF: $e');
              await Printing.sharePdf(bytes: bytes, filename: fileName);
              _showSuccessMessage('Impossible d\'écrire localement, PDF partagé.');
            }
            break;
          }

          _showErrorMessage('Document inconnu pour téléchargement');
          break;

        case 'print':
          if (isDevis) {
            final Devis devis = doc;

            final dynUser = ref.read(currentUserProvider);
            final User? user = _extractUserFrom(dynUser);

            if (user == null) {
              _showErrorMessage('Impossible de récupérer les infos du garage pour générer le PDF.');
              break;
            }

            final bytes = await PdfService.instance.buildDevisPdfBytes(devis, user, footerNote: 'Généré par GarageLink');
            await PdfService.instance.printPdfBytes(bytes);
            _showSuccessMessage('Impression Devis lancée');
            break;
          }

          if (isFacture) {
            final Facture facture = doc;
            final bytes = await PdfService.instance.buildFacturePdfBytes(facture, footerNote: 'Généré par GarageLink');
            await PdfService.instance.printPdfBytes(bytes);
            _showSuccessMessage('Impression Facture lancée');
            break;
          }

          _showErrorMessage('Document inconnu pour impression');
          break;

        default:
          _showErrorMessage('Action inconnue');
      }
    } catch (e, st) {
      debugPrint('Erreur action $action: $e\n$st');
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getProcessingMessage(String action) {
    switch (action) {
      case 'send':
        return 'Envoi en cours...';
      case 'download':
        return 'Génération PDF...';
      case 'print':
        return 'Préparation impression...';
      default:
        return 'Traitement...';
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: PreviewColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

 

  

  @override
  Widget build(BuildContext context) {
    final Facture? previewFacture = widget.facture;
    final Devis? previewDevisFromParam = widget.devis;
    final Devis previewDevisFromProvider = ref.watch(devisProvider).toDevis();

    final bool haveFacture = previewFacture != null;
    final Devis previewDevis = previewDevisFromParam ?? previewDevisFromProvider;

    final bool isFacture = haveFacture;

    // watch currentUserProvider (could be AsyncValue<User?> or User?)
    final dynamic userWatch = ref.watch(currentUserProvider);
    final User? user = _extractUserFrom(userWatch);

    // build a widget for garage info that handles loading/error when provider is AsyncValue
    

    final String safeClientForFilename = isFacture
        ? ((previewFacture.clientInfo.nom?.isNotEmpty ?? false) ? previewFacture.clientInfo.nom! : 'client')
            .replaceAll(RegExp(r"[^A-Za-z0-9_]"), "_")
        : ((previewDevis.clientName.isNotEmpty ? previewDevis.clientName : 'client'))
            .replaceAll(RegExp(r"[^A-Za-z0-9_]"), "_");

    return Scaffold(
      backgroundColor: PreviewColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildModernSliverAppBar(isFacture ? null : previewDevis, isFacture),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView(
                          padding: const EdgeInsets.all(0),
                          children: [
                           
                            // Le PDF preview
                            SizedBox(
                              height: 600, // hauteur fixe ou adaptative selon besoin
                              child: PdfPreview(
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                                build: (format) async {
                                  if (isFacture) {
                                    return await PdfService.instance
                                        .buildFacturePdfBytes(previewFacture, footerNote: 'Généré par GarageLink');
                                  } else {
                                    // ensure we have a user to pass
                                    if (user == null) {
                                      // attempt to read synchronously if not in watch
                                      final dyn = ref.read(currentUserProvider);
                                      final User? u = _extractUserFrom(dyn);
                                      if (u == null) {
                                        // fallback: show an empty PDF (or throw) — here we return an empty doc
                                        debugPrint('Aucun user disponible pour générer le PDF du devis.');
                                        return (await PdfService.instance.buildDevisPdfBytes(previewDevis, User(username: '', email: ''), footerNote: 'Généré par GarageLink'));
                                      }
                                      return await PdfService.instance.buildDevisPdfBytes(previewDevis, u, footerNote: 'Généré par GarageLink');
                                    }
                                    return await PdfService.instance
                                        .buildDevisPdfBytes(previewDevis, user, footerNote: 'Généré par GarageLink');
                                  }
                                },
                                pdfFileName: '${isFacture ? 'facture' : 'devis'}_$safeClientForFilename.pdf',
                                allowPrinting: true,
                                allowSharing: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: PreviewColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _processingMessage,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernSliverAppBar(Devis? devis, bool isFacture) {
    final String title = isFacture ? 'Facture' : 'Devis';
    final DevisStatus? status = isFacture ? null : devis?.status;
    final String clientLabel = isFacture
        ? (widget.facture?.clientInfo.nom?.isNotEmpty ?? false ? widget.facture!.clientInfo.nom! : 'Client')
        : (devis?.clientName.isNotEmpty ?? false ? devis!.clientName : 'Client');

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: PreviewColors.primary,
      flexibleSpace: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FlexibleSpaceBar(
            title: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.3),
              child: _buildTitleSectionGeneric(title, status, clientLabel, isFacture),
            ),
            background: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PreviewColors.primary, PreviewColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  top: -50,
                  right: -50,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 100,
                  child: Transform.scale(
                    scale: _scaleAnimation.value * 0.6,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 20,
                  child: Transform.translate(
                    offset: Offset(_slideAnimation.value * 0.5, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isFacture ? Icons.receipt_long : Icons.description,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      leading: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slideAnimation.value * 0.3, 0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          );
        },
      ),
      actions: _buildAnimatedActionsGeneric(isFacture),
    );
  }

  Widget _buildTitleSectionGeneric(String title, DevisStatus? status, String clientLabel, bool isFacture) {
    final Color statusColor = isFacture ? PreviewColors.success : (status == null ? Colors.grey : _getStatusColor(status));
    final String statusText = isFacture ? 'FACTURE' : (status == null ? '' : _getStatusText(status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (!isFacture && status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: statusColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (isFacture)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: statusColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  'FACTURE',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          clientLabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnimatedActionsGeneric(bool isFacture) {
    final Object docToUse = isFacture ? (widget.facture as Object) : (widget.devis ?? ref.watch(devisProvider).toDevis());

    final actions = [
      _buildActionButton(
        icon: Icons.send_rounded,
        tooltip: 'Envoyer ${isFacture ? 'facture' : 'devis'}',
        onPressed: () => _handleAction('send', doc: docToUse),
        isPrimary: true,
      ),
      _buildActionButton(
        icon: Icons.download_rounded,
        tooltip: 'Télécharger PDF',
        onPressed: () => _handleAction('download', doc: docToUse),
      ),
      _buildActionButton(
        icon: Icons.print_rounded,
        tooltip: 'Imprimer',
        onPressed: () => _handleAction('print', doc: docToUse),
      ),
    ];

    return actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;

      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _slideAnimation.value * (1 + index * 0.1),
              0,
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: action,
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: _isProcessing ? null : onPressed,
        splashRadius: 20,
      ),
    );
  }

  Color _getStatusColor(DevisStatus status) {
    switch (status) {
      case DevisStatus.brouillon:
        return Colors.orange;
      case DevisStatus.envoye:
        return Colors.blue;
      case DevisStatus.accepte:
        return PreviewColors.success;
      case DevisStatus.refuse:
        return Colors.red;
    }
  }

  String _getStatusText(DevisStatus status) {
    switch (status) {
      case DevisStatus.brouillon:
        return 'BROUILLON';
      case DevisStatus.envoye:
        return 'ENVOYÉ';
      case DevisStatus.accepte:
        return 'ACCEPTÉ';
      case DevisStatus.refuse:
        return 'REFUSÉ';
    }
  }
}
