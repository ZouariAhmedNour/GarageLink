// lib/MecanicienScreens/Reservations/garage_reservations_screen.dart
import 'package:flutter/material.dart';
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

class _GarageReservationsScreenState extends ConsumerState<GarageReservationsScreen> {
  Reservation? selected;
  final ScrollController _messagesController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _proposedDate;
  String? _proposedHour; // "HH:mm"

  // NOTIF: conservation du dernier nombre connu de réservations
  int _lastReservationsCount = 0;

  @override
  void initState() {
    super.initState();
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
              const SnackBar(content: Text('Choisissez une date et une heure pour proposer un créneau'))
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action envoyée')));
      }
    } catch (e) {
      debugPrint('action error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message envoyé')));
      }
    } catch (e) {
      debugPrint('send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: isClient ? Colors.blue.shade600 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isClient ? Colors.white : Colors.black)),
          const SizedBox(height: 6),
          Text(displayText, style: TextStyle(color: isClient ? Colors.white : Colors.black)),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(DateFormat('dd/MM/yyyy HH:mm').format(timestamp), style: TextStyle(fontSize: 11, color: isClient ? Colors.white70 : Colors.black54)),
            ),
        ],
      ),
    );
  }

  Widget _twoColumnLayout(BuildContext context, List<Reservation> reservations) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('Demandes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
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
                    return ListTile(
                      selected: isSel,
                      title: Text(r.clientName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(r.serviceName ?? r.serviceId, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(r.creneauDemande.date != null ? DateFormat('dd/MM').format(r.creneauDemande.date!) : ''),
                      onTap: () => setState(() => selected = r),
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
      padding: const EdgeInsets.all(12),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final r = reservations[idx];
        final serviceLabel = (r.serviceName != null && r.serviceName!.isNotEmpty) ? r.serviceName! : r.serviceId;
        final dateStr = r.creneauDemande.date != null ? DateFormat('dd/MM/yyyy').format(r.creneauDemande.date!) : '';
        final timeStr = r.creneauDemande.heureDebut ?? r.creneauPropose?.heureDebut ?? '';

        final garageDisplayText = _garageProposalLabel(r) ?? r.messageGarage;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(serviceLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Chip(label: Text(_statusLabel(r.status))),
                  ],
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _messageBubble(title: 'Client', text: r.messageClient!, isClient: true, timestamp: r.updatedAt, reservationForContext: r),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Message au client (optionnel)')),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Accepter la réservation'),
                            content: const Text('Confirmer l\'acceptation ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
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
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Refuser la réservation'),
                            content: const Text('Voulez-vous refuser cette réservation ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
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
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => selected = r);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, sheetSetState) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Proposer un nouveau créneau', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () async {
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
                                              child: Text(_proposedDate == null ? 'Choisir date' : DateFormat('dd/MM/yyyy').format(_proposedDate!)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              value: _proposedHour,
                                              hint: const Text('Heure'),
                                              items: _generateTimeOptions().map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                              onChanged: (v) {
                                                sheetSetState(() => _proposedHour = v);
                                                setState(() => _proposedHour = v);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                sheetSetState(() {
                                                  _proposedDate = null;
                                                  _proposedHour = null;
                                                });
                                                setState(() {
                                                  _proposedDate = null;
                                                  _proposedHour = null;
                                                });
                                              },
                                              child: const Text('Réinitialiser'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _performAction(action: 'contre_proposer');
                                            },
                                            child: const Text('Envoyer la proposition'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => selected = r);
                        _sendMessageAsGarage();
                      },
                      child: const Text('Envoyer'),
                    ),
                  ],
                ),
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
      return const Center(child: Text('Sélectionnez une réservation à gauche'));
    }

    final r = selected!;
    final requestedDateStr = r.creneauDemande.date != null ? DateFormat('dd/MM/yyyy').format(r.creneauDemande.date!) : '';
    final requestedTimeStr = r.creneauDemande.heureDebut ?? '';
    final proposed = r.creneauPropose;

    final garageDisplayTextDetail = _garageProposalLabel(r) ?? r.messageGarage;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(r.clientPhone, style: const TextStyle(color: Colors.black54)),
                ]),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$requestedDateStr ${requestedTimeStr.isNotEmpty ? '• $requestedTimeStr' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Chip(label: Text(_statusLabel(r.status))),
                ],
              ),
            ],
          ),
        ),

        if (proposed != null)
          Container(
            width: double.infinity,
            color: Colors.blueGrey.withOpacity(0.03),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Créneau proposé: ${proposed.date != null ? DateFormat('dd/MM/yyyy').format(proposed.date!) : ''} ${proposed.heureDebut ?? ''}',
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            controller: _messagesController,
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 12),

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Message au client (optionnel)'))),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _sendMessageAsGarage, child: const Text('Envoyer')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Accepter la réservation'),
                          content: const Text('Confirmer l\'acceptation ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _performAction(action: 'accepter');
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Accepter'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Refuser la réservation'),
                          content: const Text('Voulez-vous refuser cette réservation ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
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
                  ElevatedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, sheetSetState) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Proposer un nouveau créneau', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
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
                                          child: Text(_proposedDate == null ? 'Choisir date' : DateFormat('dd/MM/yyyy').format(_proposedDate!)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _proposedHour,
                                          hint: const Text('Heure'),
                                          items: _generateTimeOptions().map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                          onChanged: (v) {
                                            sheetSetState(() => _proposedHour = v);
                                            setState(() => _proposedHour = v);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            sheetSetState(() {
                                              _proposedDate = null;
                                              _proposedHour = null;
                                            });
                                            setState(() {
                                              _proposedDate = null;
                                              _proposedHour = null;
                                            });
                                          },
                                          child: const Text('Réinitialiser'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _performAction(action: 'contre_proposer');
                                        },
                                        child: const Text('Envoyer la proposition'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Contre-proposer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);
    final reservations = state.reservations;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages - Garagiste')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : reservations.isEmpty
              ? const Center(child: Text('Aucune réservation'))
              : LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth < 720) {
                    return _mobileListLayout(context, reservations);
                  } else {
                    return _twoColumnLayout(context, reservations);
                  }
                }),
    );
  }
}
