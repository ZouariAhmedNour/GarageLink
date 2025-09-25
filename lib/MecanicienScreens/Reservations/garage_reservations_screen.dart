// lib/MecanicienScreens/Reservations/garage_reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:garagelink/models/reservation.dart';
import 'package:garagelink/providers/reservation_provider.dart';

// NOTIF: import du provider global de notifications
import 'package:garagelink/providers/notification_provider.dart';

class GarageReservationsScreen extends ConsumerStatefulWidget {
  const GarageReservationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GarageReservationsScreen> createState() => _GarageReservationsScreenState();
}

class _GarageReservationsScreenState extends ConsumerState<GarageReservationsScreen> with TickerProviderStateMixin {
  Reservation? selected;
  final ScrollController _messagesController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _proposedDate;
  String? _proposedHour; // "HH:mm"

  // NOTIF: conservation du dernier nombre connu de réservations
  int _lastReservationsCount = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color primaryBlue = Color(0xFF357ABD);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(reservationsProvider.notifier).loadAll();
        // initialise le compteur connu après le premier chargement
        _lastReservationsCount = ref.read(reservationsProvider).reservations.length;
      } catch (e) {
        debugPrint('loadAll err: $e');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messagesController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // NOTIF: vérifie s'il y a plus d'éléments et incrémente le provider global si besoin
  void _maybeNotifyNewReservations() {
    final newCount = ref.read(reservationsProvider).reservations.length;
    if (newCount > _lastReservationsCount) {
      final diff = newCount - _lastReservationsCount;
      ref.read(newNotificationProvider.notifier).state += diff;
    }
    _lastReservationsCount = newCount;
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _proposedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _proposedDate = date);
  }

  String? _buildGarageMessageToSend(String? rawMessage, DateTime? date, String? hour) {
    final m = rawMessage?.trim();
    final datePart = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    final hourPart = (hour ?? '').trim();

    // Si pas de date/heure, renvoyer le message brut (ou null si vide)
    if (datePart.isEmpty && hourPart.isEmpty) {
      return (m != null && m.isNotEmpty) ? m : null;
    }

    var label = 'Nouveau créneau proposé : ${datePart}${datePart.isNotEmpty && hourPart.isNotEmpty ? ' • ' : ' '}$hourPart'.trim();

    if (m == null || m.isEmpty) return label;
    return '$label — $m';
  }

  /// Construit un message lorsqu'on accepte la réservation.
  /// Si un créneau proposé existe on inclut la date/heure, sinon message générique.
  String? _buildGarageAcceptMessage(Reservation r) {
    final proposed = r.creneauPropose;
    String base;
    if (proposed != null && (proposed.date != null || (proposed.heureDebut ?? '').isNotEmpty)) {
      final datePart = proposed.date != null ? DateFormat('dd/MM/yyyy').format(proposed.date!) : '';
      final hourPart = (proposed.heureDebut ?? '').trim();
      base = 'Créneau confirmé : ${datePart}${datePart.isNotEmpty && hourPart.isNotEmpty ? ' • ' : ' '}$hourPart'.trim();
    } else {
      base = 'Réservation acceptée';
    }

    final note = _messageController.text.trim();
    if (note.isNotEmpty) return '$base — $note';
    return base;
  }

  /// Effectue une action sur la réservation sélectionnée et recharge la liste
  /// pour s'assurer que tous les écrans affichent la version mise à jour.
  Future<void> _performAction({required String action}) async {
    if (selected == null) return;

    try {
      // Validation : si action = contre_proposer, newDate + newHeureDebut requis
      if (action == 'contre_proposer') {
        if (_proposedDate == null || _proposedHour == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Choisissez une date et une heure pour proposer un créneau'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final notifier = ref.read(reservationsProvider.notifier);

      // Construire le message à envoyer en fonction de l'action
      String? messageToSend;
      String actionToSend = action;

      if (action == 'contre_proposer') {
        messageToSend = _buildGarageMessageToSend(_messageController.text, _proposedDate, _proposedHour);
      } else if (action == 'accepter') {
        messageToSend = _buildGarageAcceptMessage(selected!);
        if (selected!.status == ReservationStatus.contrePropose) {
          // Ajuste actionToSend si nécessaire selon ton backend
        }
      } else {
        messageToSend = (_messageController.text.isNotEmpty ? _messageController.text.trim() : null);
      }

      // Appel updateReservation
      await notifier.updateReservation(
        id: selected!.id!,
        action: actionToSend,
        newDate: (action == 'contre_proposer') ? _proposedDate : null,
        newHeureDebut: (action == 'contre_proposer') ? _proposedHour : null,
        message: messageToSend,
        sender: 'garage',
      );

      // --- recharger la liste depuis le backend pour assurer cohérence ---
      await notifier.loadAll();

      // NOTIF: détecte nouvelles réservations (par ex. si backend a créé une nouvelle res)
      _maybeNotifyNewReservations();

      // NOTIF: si on a envoyé un message/contre-proposition, prévenir le tableau de bord
      if (messageToSend != null && messageToSend.trim().isNotEmpty) {
        ref.read(newNotificationProvider.notifier).state += 1;
      }

      if (!mounted) return;

      // récupérer la version mise à jour depuis le provider
      final updated = ref.read(reservationsProvider).reservations.firstWhere(
            (r) => r.id == selected!.id,
            orElse: () => selected!,
          );

      setState(() {
        selected = updated;
        _messageController.clear();
        _proposedDate = null;
        _proposedHour = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action envoyée'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('action error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'action: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Envoie un message (et si une date/heure proposée est renseignée, on l'envoie aussi).
  Future<void> _sendMessageAsGarage() async {
    if (selected == null) return;
    final rawText = _messageController.text.trim();
    if (rawText.isEmpty && _proposedDate == null && _proposedHour == null) return;

    try {
      final notifier = ref.read(reservationsProvider.notifier);

      // Construire le message à envoyer (avec date/heure si present)
      final messageToSend = _buildGarageMessageToSend(rawText.isNotEmpty ? rawText : null, _proposedDate, _proposedHour);

      // Ici on utilise 'contre_proposer' pour conserver la logique d'envoi d'un message et/ou créneau
      await notifier.updateReservation(
        id: selected!.id!,
        action: 'contre_proposer',
        newDate: _proposedDate,
        newHeureDebut: _proposedHour,
        message: messageToSend,
        sender: 'garage',
      );

      // --- recharger la liste pour synchroniser toutes les vues ---
      await notifier.loadAll();

      // NOTIF: détecte nouvelles réservations (si backend en a créé)
      _maybeNotifyNewReservations();

      // NOTIF: prévenir le tableau de bord qu'un message a été envoyé
      if (messageToSend != null && messageToSend.trim().isNotEmpty) {
        ref.read(newNotificationProvider.notifier).state += 1;
      }

      if (!mounted) return;

      final updated = ref.read(reservationsProvider).reservations.firstWhere(
            (r) => r.id == selected!.id,
            orElse: () => selected!,
          );

      setState(() {
        _messageController.clear();
        _proposedDate = null;
        _proposedHour = null;
        selected = updated;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<String> _generateTimeOptions() {
    final options = <String>[];
    for (int h = 8; h <= 18; h++) {
      options.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 18) options.add('${h.toString().padLeft(2, '0')}:30');
    }
    return options;
  }

  String _statusLabel(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.enAttente:
        return 'En attente';
      case ReservationStatus.accepte:
        return 'Acceptée';
      case ReservationStatus.refuse:
        return 'Refusée';
      case ReservationStatus.contrePropose:
        return 'Contre-proposée';
      case ReservationStatus.annule:
        return 'Annulée';
    }
  }

  Color _statusColor(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.enAttente:
        return Colors.orange;
      case ReservationStatus.accepte:
        return Colors.green;
      case ReservationStatus.refuse:
        return Colors.red;
      case ReservationStatus.contrePropose:
        return primaryBlue;
      case ReservationStatus.annule:
        return Colors.grey;
    }
  }

  /// Construit un texte lisible pour une proposition envoyée par le client (inchangé)
  String? _clientProposalLabel(Reservation r) {
    final lower = (r.messageClient ?? '').toLowerCase();
    final hasProposalKeyword = lower.contains('proposition') || lower.contains('contre') || lower.contains('créneau');
    if (!hasProposalKeyword) return null;
    DateTime? d = r.creneauPropose?.date ?? r.creneauDemande.date;
    String? h = r.creneauPropose?.heureDebut ?? r.creneauDemande.heureDebut;
    if (d == null && (r.messageClient ?? '').contains(RegExp(r'\d{2}\/\d{2}\/\d{4}'))) {
      final match = RegExp(r'(\d{2}\/\d{2}\/\d{4})').firstMatch(r.messageClient!);
      if (match != null) {
        try {
          d = DateFormat('dd/MM/yyyy').parse(match.group(1)!);
        } catch (_) {}
      }
    }
    if (d == null && h == null) return null;
    final datePart = d != null ? DateFormat('dd/MM/yyyy').format(d) : '';
    final hourPart = h ?? '';
    return 'Nouvelle proposition : ${datePart}${datePart.isNotEmpty && hourPart.isNotEmpty ? ' • ' : ' '}$hourPart'.trim();
  }

  /// Construit un texte lisible pour une proposition envoyée par le garage
  String? _garageProposalLabel(Reservation r) {
    final proposed = r.creneauPropose;
    if (proposed == null) return null;

    final d = proposed.date;
    final h = proposed.heureDebut;

    if (d == null && (h == null || h.isEmpty)) return null;

    final datePart = d != null ? DateFormat('dd/MM/yyyy').format(d) : '';
    final hourPart = (h ?? '').trim();
    String label = 'Nouveau créneau proposé : ${datePart}${datePart.isNotEmpty && hourPart.isNotEmpty ? ' • ' : ' '}$hourPart'.trim();

    // Si le backend a aussi fourni un message texte côté garage, on l'ajoute collé après un séparateur " — "
    final msg = r.messageGarage?.trim();
    if (msg != null && msg.isNotEmpty) {
      if (!msg.contains(datePart) && !msg.contains(hourPart)) {
        label = '$label — $msg';
      } else {
        label = '$label — $msg';
      }
    }

    return label;
  }

  Widget _messageBubble({required String title, required String text, required bool isClient, DateTime? timestamp, Reservation? reservationForContext}) {
    String displayText = text;
    if (isClient && reservationForContext != null) {
      final proposalLabel = _clientProposalLabel(reservationForContext);
      if (proposalLabel != null) displayText = proposalLabel;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: isClient ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isClient ? Icons.person : Icons.build,
                size: 16,
                color: isClient ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isClient ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: TextStyle(
              color: isClient ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isClient ? Colors.white70 : Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _twoColumnLayout(BuildContext context, List<Reservation> reservations) {
    return Row(
      children: [
        Container(
          width: 320,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
            color: Colors.white, // <-- left panel background = white
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.inbox, color: primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'Demandes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: primaryBlue),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ref.read(reservationsProvider.notifier).loadAll();
                        // NOTIF: vérifier si de nouvelles réservations sont arrivées suite au refresh manuel
                        _maybeNotifyNewReservations();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, i) {
                    final r = reservations[i];
                    final isSel = selected?.id == r.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: isSel ? 6 : 2,
                      color: Colors.white, // <-- card background = white
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: primaryBlue),
                        title: Text(
                          r.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSel ? primaryBlue : null,
                          ),
                        ),
                        subtitle: Text(
                          r.serviceName ?? r.serviceId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (r.creneauDemande.date != null)
                              Text(
                                DateFormat('dd/MM').format(r.creneauDemande.date!),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            const SizedBox(height: 6),
                            Chip(
                              label: Text(_statusLabel(r.status)),
                              backgroundColor: _statusColor(r.status).withOpacity(0.12),
                              labelStyle: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => selected = r);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _conversationPanel(context)),
      ],
    );
  }

  Widget _mobileListLayout(BuildContext context, List<Reservation> reservations) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, idx) {
        final r = reservations[idx];
        final serviceLabel = (r.serviceName != null && r.serviceName!.isNotEmpty) ? r.serviceName! : r.serviceId;
        final dateStr = r.creneauDemande.date != null ? DateFormat('dd/MM/yyyy').format(r.creneauDemande.date!) : '';
        final timeStr = r.creneauDemande.heureDebut ?? r.creneauPropose?.heureDebut ?? '';

        final garageDisplayText = _garageProposalLabel(r) ?? r.messageGarage;

        return Card(
          color: Colors.white, // <-- card background white
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          child: ExpansionTile(
            leading: const Icon(Icons.person, color: primaryBlue),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          serviceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(_statusLabel(r.status)),
                        backgroundColor: _statusColor(r.status).withOpacity(0.12),
                        labelStyle: TextStyle(color: _statusColor(r.status)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _messageBubble(
                title: 'Demande',
                text: '${r.serviceName ?? r.serviceId}\n📅 ${dateStr} ${timeStr}\n\n${r.descriptionDepannage}',
                isClient: true,
                timestamp: r.createdAt,
                reservationForContext: r,
              ),

              if (garageDisplayText != null)
                _messageBubble(
                  title: 'Garage',
                  text: garageDisplayText,
                  isClient: false,
                  timestamp: r.updatedAt,
                  reservationForContext: r,
                ),

              if (r.messageClient != null)
                _messageBubble(
                  title: 'Client',
                  text: r.messageClient!,
                  isClient: true,
                  timestamp: r.updatedAt,
                  reservationForContext: r,
                ),

              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message au client (optionnel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Accepter la réservation'),
                            ],
                          ),
                          content: const Text('Confirmer l\'acceptation ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Non'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        setState(() => selected = r);
                        await _performAction(action: 'accepter');
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Accepter'),
                    style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.close, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Refuser la réservation'),
                            ],
                          ),
                          content: const Text('Voulez-vous refuser cette réservation ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        setState(() => selected = r);
                        await _performAction(action: 'refuser');
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Refuser'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => selected = r);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, sheetSetState) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                  left: 16,
                                  right: 16,
                                  top: 16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.schedule, color: primaryBlue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Proposer un nouveau créneau',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              HapticFeedback.lightImpact();
                                              final now = DateTime.now();
                                              final date = await showDatePicker(
                                                context: context,
                                                initialDate: _proposedDate ?? now,
                                                firstDate: now,
                                                lastDate: now.add(const Duration(days: 365)),
                                              );
                                              if (date != null) {
                                                sheetSetState(() => _proposedDate = date);
                                                setState(() => _proposedDate = date);
                                              }
                                            },
                                            icon: const Icon(Icons.calendar_today),
                                            label: Text(
                                              _proposedDate == null ? 'Choisir date' : DateFormat('dd/MM/yyyy').format(_proposedDate!),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _proposedHour,
                                            hint: const Text('Heure'),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            items: _generateTimeOptions().map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                            onChanged: (v) {
                                              HapticFeedback.lightImpact();
                                              sheetSetState(() => _proposedHour = v);
                                              setState(() => _proposedHour = v);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              sheetSetState(() {
                                                _proposedDate = null;
                                                _proposedHour = null;
                                              });
                                              setState(() {
                                                _proposedDate = null;
                                                _proposedHour = null;
                                              });
                                            },
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Réinitialiser'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.icon(
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).pop();
                                            _performAction(action: 'contre_proposer');
                                          },
                                          icon: const Icon(Icons.send),
                                          label: const Text('Envoyer la proposition'),
                                          style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Contre-proposer'),
                    style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => selected = r);
                      _sendMessageAsGarage();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer'),
                    style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _conversationPanel(BuildContext context) {
    if (selected == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Sélectionnez une réservation à gauche', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    final r = selected!;
    final requestedDateStr = r.creneauDemande.date != null ? DateFormat('dd/MM/yyyy').format(r.creneauDemande.date!) : '';
    final requestedTimeStr = r.creneauDemande.heureDebut ?? '';
    final proposed = r.creneauPropose;

    final garageDisplayTextDetail = _garageProposalLabel(r) ?? r.messageGarage;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, // <-- header background white
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            r.clientName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.clientPhone,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$requestedDateStr ${requestedTimeStr.isNotEmpty ? '• $requestedTimeStr' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_statusLabel(r.status)),
                      backgroundColor: _statusColor(r.status).withOpacity(0.12),
                      labelStyle: TextStyle(color: _statusColor(r.status)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (proposed != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, // <-- proposed bar white
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: primaryBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Créneau proposé: ${proposed.date != null ? DateFormat('dd/MM/yyyy').format(proposed.date!) : ''} ${proposed.heureDebut ?? ''}',
                      style: TextStyle(color: primaryBlue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              controller: _messagesController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _messageBubble(
                      title: 'Demande',
                      text: '${r.serviceName ?? r.serviceId}\n📅 ${requestedDateStr} ${requestedTimeStr}\n\n${r.descriptionDepannage}',
                      isClient: true,
                      timestamp: r.createdAt,
                      reservationForContext: r,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (garageDisplayTextDetail != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _messageBubble(
                        title: 'Garage',
                        text: garageDisplayTextDetail,
                        isClient: false,
                        timestamp: r.updatedAt,
                        reservationForContext: r,
                      ),
                    ),

                  if (r.messageClient != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _messageBubble(
                        title: 'Client',
                        text: r.messageClient!,
                        isClient: true,
                        timestamp: r.updatedAt,
                        reservationForContext: r,
                      ),
                    ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // <-- input area white
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message au client (optionnel)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _sendMessageAsGarage();
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Envoyer'),
                      style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.check, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Accepter la réservation'),
                              ],
                            ),
                            content: const Text('Confirmer l\'acceptation ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.green), child: const Text('Oui')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _performAction(action: 'accepter');
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Accepter'),
                      style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.close, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Refuser la réservation'),
                              ],
                            ),
                            content: const Text('Voulez-vous refuser cette réservation ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Oui')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _performAction(action: 'refuser');
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Refuser'),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, sheetSetState) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).viewInsets.bottom,
                                    left: 16,
                                    right: 16,
                                    top: 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.schedule, color: primaryBlue),
                                          SizedBox(width: 8),
                                          Text(
                                            'Proposer un nouveau créneau',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                HapticFeedback.lightImpact();
                                                final now = DateTime.now();
                                                final date = await showDatePicker(
                                                  context: context,
                                                  initialDate: _proposedDate ?? now,
                                                  firstDate: now,
                                                  lastDate: now.add(const Duration(days: 365)),
                                                );
                                                if (date != null) {
                                                  sheetSetState(() => _proposedDate = date);
                                                  setState(() => _proposedDate = date);
                                                }
                                              },
                                              icon: const Icon(Icons.calendar_today),
                                              label: Text(
                                                _proposedDate == null ? 'Choisir date' : DateFormat('dd/MM/yyyy').format(_proposedDate!),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              value: _proposedHour,
                                              hint: const Text('Heure'),
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              items: _generateTimeOptions().map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                              onChanged: (v) {
                                                HapticFeedback.lightImpact();
                                                sheetSetState(() => _proposedHour = v);
                                                setState(() => _proposedHour = v);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                sheetSetState(() {
                                                  _proposedDate = null;
                                                  _proposedHour = null;
                                                });
                                                setState(() {
                                                  _proposedDate = null;
                                                  _proposedHour = null;
                                                });
                                              },
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Réinitialiser'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton.icon(
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              Navigator.of(context).pop();
                                              _performAction(action: 'contre_proposer');
                                            },
                                            icon: const Icon(Icons.send),
                                            label: const Text('Envoyer la proposition'),
                                            style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Contre-proposer'),
                      style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);
    final reservations = state.reservations;

    return Scaffold(
      backgroundColor: Colors.white, // <-- entire page background = white
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Messages - Garagiste',
          style: TextStyle( color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Naviguer vers notifications si implémenté
            },
          ),
        ],
      ),
      body: state.loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: primaryBlue),
                  SizedBox(height: 16),
                  Text('Chargement des réservations...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : reservations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune réservation', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720) {
                      return _mobileListLayout(context, reservations);
                    } else {
                      return _twoColumnLayout(context, reservations);
                    }
                  },
                ),
    );
  }
}
