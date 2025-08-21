import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/providers/notif_providers.dart';
import 'package:garagelink/services/share_email_service.dart';

// Constantes de design
class AppColors {
  static const Color primary = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF5A9BD8);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
}

class NotifScreen extends ConsumerStatefulWidget {
  const NotifScreen({super.key});

  @override
  ConsumerState<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends ConsumerState<NotifScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _vinCtrl = TextEditingController();
  final TextEditingController _numClientCtrl = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _filterNom = '';
  String _filterVin = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomCtrl.dispose();
    _vinCtrl.dispose();
    _numClientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(notifProvider);
    final filteredClients = _getFilteredClients(clients);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterSection(),
            _buildResultsHeader(filteredClients.length),
            Expanded(child: _buildClientsList(filteredClients)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(

      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
      color: Colors.white, // Explicitly sets title text color
      fontWeight: FontWeight.w600,
    ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_active, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          color: Colors.white,
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
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
              Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtres de recherche',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNomFilter(),
          const SizedBox(height: 12),
          _buildVinFilter(),
          if (_errorMessage != null) _buildErrorMessage(),
        ],
      ),
    );
  }

  Widget _buildNomFilter() {
    return TextField(
      controller: _nomCtrl,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Rechercher par nom client...',
        hintStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.person_search, color: AppColors.primary),
        suffixIcon: _filterNom.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _nomCtrl.clear();
                  setState(() => _filterNom = '');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      onChanged: (val) {
        setState(() {
          _filterNom = val;
          _errorMessage = null;
        });
        _provideFeedback();
      },
    );
  }

  Widget _buildVinFilter() {
    return NumeroSerieInput(
      vinCtrl: _vinCtrl,
      numLocalCtrl: _numClientCtrl,
      onChanged: (val) {
        setState(() {
          _filterVin = val;
          _errorMessage = null;
        });
        _provideFeedback();
      },
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            '$count client${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList(List<Client> clients) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (clients.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildClientCard(clients[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun client trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres de recherche',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client, int index) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 24,
            child: Text(
              client.nom.isNotEmpty ? client.nom[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            client.nom,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.confirmation_number, 
                       size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'N° série: ${client.numSerie ?? 'Non renseigné'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (client.email.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.email_outlined, 
                         size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        client.email,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: _buildActionButton(client),
        ),
      ),
    );
  }

  Widget _buildActionButton(Client client) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.email, color: Colors.white, size: 20),
        onPressed: () => _openMessageDialog(context, client),
        tooltip: 'Envoyer un email',
      ),
    );
  }

  void _openMessageDialog(BuildContext context, Client client) {
    final msgCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: Icon(Icons.email, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nouveau message', style: TextStyle(fontSize: 18)),
                  Text(
                    'à ${client.nom}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: TextField(
          controller: msgCtrl,
          decoration: InputDecoration(
            hintText: 'Saisissez votre message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          maxLines: 4,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _sendEmail(context, client, msgCtrl.text),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, Client client, String message) async {
    if (message.trim().isEmpty) {
      setState(() => _errorMessage = 'Le message ne peut pas être vide');
      return;
    }

    try {
      await ShareEmailService.openEmailClient(
        to: client.email,
        subject: "Notification GarageLink - ${client.nom}",
        body: message,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccessMessage('Email envoyé avec succès');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de l\'envoi: ${e.toString()}');
    }
  }

  List<Client> _getFilteredClients(List<Client> clients) {
    return clients.where((client) {
      final matchNom = client.nom.toLowerCase().contains(_filterNom.toLowerCase());
      final matchVin = (client.numSerie ?? '').toLowerCase().contains(_filterVin.toLowerCase());
      return matchNom && matchVin;
    }).toList();
  }

  void _provideFeedback() {
    HapticFeedback.lightImpact();
  }

  void _refreshData() {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    // Simuler un refresh
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessMessage('Données actualisées');
      }
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
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
}