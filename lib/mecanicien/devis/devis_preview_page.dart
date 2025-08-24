// lib/mecanicien/devis/devis_preview_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:garagelink/utils/devis_actions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

// Palette de couleurs pour la prévisualisation
class PreviewColors {
  static const Color primary = Color(0xFF357ABD);
  static const Color primaryDark = Color(0xFF2A5F8F);
  static const Color secondary = Color(0xFF4A90E2);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color surface = Color(0xFFFAFAFA);
}

class DevisPreviewPage extends ConsumerStatefulWidget {
  final Devis? devis;
  const DevisPreviewPage({super.key, this.devis});

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
      final boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Erreur capture PNG: $e");
      return null;
    }
  }

  Future<void> _handleAction(String action, Devis devis, bool isFacture) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = _getProcessingMessage(action);
    });

    HapticFeedback.mediumImpact();

    try {
      switch (action) {
        case 'send':
          final png = await _capturePreviewPng();
          await generateAndSendDevis(ref, context, previewPng: png, devisToSend: devis);
          _showSuccessMessage('${isFacture ? 'Facture' : 'Devis'} envoyé avec succès');
          break;
       case 'download':
  final bytes = await PdfService.buildDevisPdf(
    devis,
    title: isFacture ? 'Facture' : 'Devis',
  );

  // Récupérer le dossier Downloads officiel
  final downloadsDir = await getDownloadsDirectory();

  if (downloadsDir != null) {
    final filePath =
        '${downloadsDir.path}/${isFacture ? 'facture' : 'devis'}_${devis.client}.pdf';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    _showSuccessMessage('PDF enregistré dans :\n$filePath');
  } else {
    _showErrorMessage("Impossible d'accéder au dossier Downloads");
  }
  break;

        case 'print':
          final bytes = await PdfService.buildDevisPdf(devis, title: isFacture ? 'Facture' : 'Devis');
          await Printing.layoutPdf(onLayout: (_) => bytes);
          _showSuccessMessage('Impression lancée');
          break;
      }
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _getProcessingMessage(String action) {
    switch (action) {
      case 'send': return 'Envoi en cours...';
      case 'download': return 'Génération PDF...';
      case 'print': return 'Préparation impression...';
      default: return 'Traitement...';
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: PreviewColors.success),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Devis previewDevis = widget.devis ?? ref.watch(devisProvider).toDevis();
    final bool isFacture = previewDevis.status == DevisStatus.accepte;

    return Scaffold(
      backgroundColor: PreviewColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildModernSliverAppBar(previewDevis, isFacture),
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
                        child: PdfPreview(
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          build: (format) => PdfService.buildDevisPdf(
                            previewDevis,
                            title: isFacture ? 'Facture' : 'Devis',
                          ),
                          pdfFileName: '${isFacture ? 'facture' : 'devis'}_${previewDevis.client}.pdf',
                          allowSharing: false,
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

  Widget _buildModernSliverAppBar(Devis devis, bool isFacture) {
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
              child: _buildTitleSection(devis, isFacture),
            ),
            background: Stack(
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PreviewColors.primary, PreviewColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Geometric patterns
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
                // Document icon overlay
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
      actions: _buildAnimatedActions(devis, isFacture),
    );
  }

  Widget _buildTitleSection(Devis devis, bool isFacture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(
              isFacture ? 'Facture' : 'Devis',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(devis.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getStatusColor(devis.status),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(devis.status),
                style: TextStyle(
                  color: _getStatusColor(devis.status),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          devis.client.isNotEmpty ? devis.client : 'Client non spécifié',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnimatedActions(Devis devis, bool isFacture) {
    final actions = [
      _buildActionButton(
        icon: Icons.send_rounded,
        tooltip: 'Envoyer ${isFacture ? 'facture' : 'devis'}',
        onPressed: () => _handleAction('send', devis, isFacture),
        isPrimary: true,
      ),
      _buildActionButton(
        icon: Icons.download_rounded,
        tooltip: 'Télécharger PDF',
        onPressed: () => _handleAction('download', devis, isFacture),
      ),
      _buildActionButton(
        icon: Icons.print_rounded,
        tooltip: 'Imprimer',
        onPressed: () => _handleAction('print', devis, isFacture),
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
        color: isPrimary 
          ? Colors.white.withOpacity(0.2) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary 
          ? Border.all(color: Colors.white.withOpacity(0.3))
          : null,
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
      default:
        return Colors.grey;
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
      default:
        return 'INCONNU';
    }
  }
}