// lib/MecanicienScreens/Reservations/client_reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:garagelink/models/reservation.dart';
import 'package:garagelink/providers/reservation_provider.dart';

class ClientReservationsScreen extends ConsumerStatefulWidget {
  const ClientReservationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientReservationsScreen> createState() =>
      _ClientReservationsScreenState();
}

class _ClientReservationsScreenState
    extends ConsumerState<ClientReservationsScreen>
    with TickerProviderStateMixin {
  Reservation? selected; // réservation actuellement ouverte (expansée)
  final TextEditingController _messageController = TextEditingController();
  DateTime? _counterDate;
  String? _counterHour;
  int _lastReservationsCount = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const Color primaryBlue = Color(0xFF357ABD);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(reservationsProvider.notifier).loadAll();
        _lastReservationsCount =
            ref.read(reservationsProvider).reservations.length;
      } catch (e) {
        debugPrint('loadAll err: $e');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Construit un message lorsque le client accepte une proposition.
  /// On essaie d'extraire la date/heure depuis messageGarage ou creneauPropose,
  /// puis on concatène le texte saisi (si présent).
  String? _buildClientAcceptMessage() {
    // extrait date/heure depuis le message du garage ou depuis creneauPropose
    final proposal =
        _extractProposalFromText(selected?.messageGarage, fallback: selected?.creneauPropose);
    final d = proposal['date'];
    final h = proposal['hour'];

    final base = (d != null || h != null)
        ? 'Proposition acceptée : ${d ?? ''}${(d != null && h != null) ? ' • ' : ' '}${h ?? ''}'.trim()
        : 'Proposition acceptée';

    final note = _messageController.text.trim();
    if (note.isNotEmpty) return '$base — $note';
    return base;
  }

  Future<void> _submitClientAction(String action) async {
    if (selected == null) return;
    // si action == contre_proposer : date & hour required
    if (action == 'contre_proposer') {
      if (_counterDate == null || _counterHour == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez date et heure', )),
        );
        return;
      }
    }

    try {
      final notifier = ref.read(reservationsProvider.notifier);

      // construire message selon l'action
      String? messageToSend;
      if (action == 'contre_proposer') {
        messageToSend = _buildClientMessageToSend(
          _messageController.text,
          _counterDate,
          _counterHour,
        );
      } else if (action == 'accepter') {
        messageToSend = _buildClientAcceptMessage();
      } else {
        messageToSend = _messageController.text.isNotEmpty
            ? _messageController.text.trim()
            : null;
      }

      await notifier.updateReservation(
        id: selected!.id!,
        action: action,
        newDate: (action == 'contre_proposer') ? _counterDate : null,
        newHeureDebut: (action == 'contre_proposer') ? _counterHour : null,
        message: messageToSend,
        sender: 'client',
      );

      // recharge pour être sûr que toutes les vues soient à jour (garage + client)
      await notifier.loadAll();

      // --- APPEL REQUIS: détecte nouvelles résas et notifie le dashboard ---
      _maybeNotifyNewReservations();

      // Optionnel : si un message a été envoyé depuis ce screen, incrémente aussi le compteur
      if (messageToSend != null && messageToSend.trim().isNotEmpty) {
        ref.read(newNotificationProvider.notifier).state += 1;
      }
      // ------------------------------------------------------------------

      // récupère la version mise à jour
      final updated = ref
          .read(reservationsProvider)
          .reservations
          .firstWhere((r) => r.id == selected!.id, orElse: () => selected!);

      if (!mounted) return;
      setState(() {
        selected = updated;
        _messageController.clear();
        _counterDate = null;
        _counterHour = null;
      });

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Réponse envoyée')));
    } catch (e) {
      debugPrint('client action error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _maybeNotifyNewReservations() {
    final newCount = ref.read(reservationsProvider).reservations.length;
    if (newCount > _lastReservationsCount) {
      final diff = newCount - _lastReservationsCount;
      ref.read(newNotificationProvider.notifier).state += diff;
    }
    _lastReservationsCount = newCount;
  }

  String? _buildClientMessageToSend(
    String? rawMessage,
    DateTime? date,
    String? hour,
  ) {
    final m = rawMessage?.trim();
    final datePart = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    final hourPart = (hour ?? '').trim();

    // Si pas de date/heure, renvoyer le message brut (ou null si vide)
    if (datePart.isEmpty && hourPart.isEmpty) {
      return (m != null && m.isNotEmpty) ? m : null;
    }

    var label =
        'Nouvelle proposition : ${datePart}${datePart.isNotEmpty && hourPart.isNotEmpty ? ' • ' : ' '}$hourPart'
            .trim();

    if (m == null || m.isEmpty) return label;
    return '$label — $m';
  }

  Future<void> _pickCounterDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _counterDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      HapticFeedback.lightImpact();
      setState(() => _counterDate = d);
    }
  }

  List<String> _generateTimeOptions() {
    final opts = <String>[];
    for (int h = 8; h <= 18; h++) {
      opts.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 18) opts.add('${h.toString().padLeft(2, '0')}:30');
    }
    return opts;
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
      case ReservationStatus.annule:
        return Colors.red;
      case ReservationStatus.contrePropose:
        return Colors.blueGrey;
    }
  }

  // ---------- NEW: extract date/hour from a text (or fallback to a Creneau) ----------
  /// Retourne {'date': 'dd/MM/yyyy' | null, 'hour': 'HH:mm' | null}
  Map<String, String?> _extractProposalFromText(
    String? text, {
    Creneau? fallback,
  }) {
    final t = (text ?? '').trim();
    if (t.isEmpty) {
      // fallback to creneau if provided
      if (fallback != null) {
        final dateStr = fallback.date != null
            ? DateFormat('dd/MM/yyyy').format(fallback.date!)
            : null;
        final hourStr = fallback.heureDebut;
        return {'date': dateStr, 'hour': hourStr};
      }
      return {'date': null, 'hour': null};
    }

    // try to find dd/MM/yyyy and HH:mm inside the text
    final dateMatch = RegExp(r'(\d{2}\/\d{2}\/\d{4})').firstMatch(t);
    final timeMatch = RegExp(r'(\d{2}:\d{2})').firstMatch(t);

    if (dateMatch != null || timeMatch != null) {
      return {'date': dateMatch?.group(1), 'hour': timeMatch?.group(1)};
    }

    // If no explicit date/time in text, fallback to creneau if available
    if (fallback != null) {
      final dateStr = fallback.date != null
          ? DateFormat('dd/MM/yyyy').format(fallback.date!)
          : null;
      final hourStr = fallback.heureDebut;
      return {'date': dateStr, 'hour': hourStr};
    }

    return {'date': null, 'hour': null};
  }

  // ---------- message card now optionally shows proposed date/hour ----------
  Widget _messageCard(
    String title,
    String text,
    bool mine,
    DateTime? ts, {
    String? proposedDate,
    String? proposedHour,
  }) {
    final bgColor = mine ? primaryBlue : Colors.white;
    final textColor = mine ? Colors.white : Colors.black87;
    final scheduleColor = mine ? Colors.white70 : Colors.black54;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(mine ? Icons.person : Icons.build, size: 16, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: textColor),
            ),
            if ((proposedDate != null && proposedDate.isNotEmpty) ||
                (proposedHour != null && proposedHour.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: scheduleColor),
                    const SizedBox(width: 6),
                    Text(
                      '${proposedDate ?? ''}${(proposedDate != null && proposedDate.isNotEmpty && proposedHour != null && proposedHour.isNotEmpty) ? ' • ' : ' '}${proposedHour ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheduleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (ts != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(ts),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheduleColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);

    return Scaffold(
      backgroundColor: Colors.white, // entire screen white
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mes réservations',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: naviguer vers notifications si nécessaire
            },
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: state.loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Chargement des réservations...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : state.reservations.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.reservations.length,
                    itemBuilder: (context, i) {
                      final r = state.reservations[i];
                      final serviceLabel =
                          (r.serviceName != null && r.serviceName!.isNotEmpty)
                              ? r.serviceName!
                              : r.serviceId;
                      final dateStr = r.creneauDemande.date != null
                          ? DateFormat('dd/MM/yyyy').format(r.creneauDemande.date!)
                          : '';
                      final timeStr =
                          r.creneauDemande.heureDebut ?? r.creneauPropose?.heureDebut ?? '';

                      final isOpen = selected?.id == r.id;

                      return Card(
                        color: Colors.white, // card white
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          key: ValueKey(r.id),
                          initiallyExpanded: isOpen,
                          onExpansionChanged: (open) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (open) {
                                selected = r;
                                // reset local pickers when opening a different reservation
                                _counterDate = null;
                                _counterHour = null;
                                _messageController.clear();
                              } else if (selected?.id == r.id) {
                                selected = null;
                                _messageController.clear();
                                _counterDate = null;
                                _counterHour = null;
                              }
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      serviceLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      r.clientName.isNotEmpty ? r.clientName : r.clientPhone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Chip(
                                    backgroundColor: _statusColor(r.status).withOpacity(0.12),
                                    label: Text(
                                      _statusLabel(r.status),
                                      style: TextStyle(
                                        color: _statusColor(r.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: [
                            // If backend filled creneauPropose show it in banner
                            if (r.creneauPropose != null)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: primaryBlue, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Créneau proposé: ${r.creneauPropose!.date != null ? DateFormat('dd/MM/yyyy').format(r.creneauPropose!.date!) : ''} ${r.creneauPropose!.heureDebut ?? ''}',
                                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Description
                            if (r.descriptionDepannage.isNotEmpty) ...[
                              const Text('Description :', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text(r.descriptionDepannage, style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 10),
                            ],

                            // Messages (history)
                            _messageCard(
                              'Ma demande',
                              '${serviceLabel}\n📅 ${dateStr} ${timeStr}\n\n${r.descriptionDepannage}',
                              true,
                              r.createdAt,
                              proposedDate: null,
                              proposedHour: null,
                            ),

                            if (r.messageGarage != null || r.creneauPropose != null)
                              () {
                                final garageProposal = _extractProposalFromText(r.messageGarage, fallback: r.creneauPropose);
                                final gd = garageProposal['date'];
                                final gh = garageProposal['hour'];
                                final garageText = (r.messageGarage != null && r.messageGarage!.trim().isNotEmpty) ? r.messageGarage! : 'Proposition';
                                return _messageCard('Garage', garageText, false, r.updatedAt, proposedDate: gd, proposedHour: gh);
                              }(),

                            if (r.messageClient != null || r.creneauPropose != null)
                              () {
                                final clientProposal = _extractProposalFromText(r.messageClient, fallback: r.creneauPropose);
                                final cd = clientProposal['date'];
                                final ch = clientProposal['hour'];
                                final clientText = (r.messageClient != null && r.messageClient!.trim().isNotEmpty) ? r.messageClient! : 'Proposition';
                                final title = (cd != null || ch != null) ? 'Ma proposition' : 'Ma réponse';
                                return _messageCard(title, clientText, true, r.updatedAt, proposedDate: cd, proposedHour: ch);
                              }(),

                            const SizedBox(height: 10),

                            // Action area: message + date/heure pickers + buttons
                            TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Message (optionnel)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickCounterDate,
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_counterDate == null ? 'Choisir date' : DateFormat('dd/MM/yyyy').format(_counterDate!), ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final hours = await showDialog<String>(
                                      context: context,
                                      builder: (_) => SimpleDialog(
                                        title: const Text('Choisir heure'),
                                        children: _generateTimeOptions().map((t) => SimpleDialogOption(onPressed: () => Navigator.pop(context, t), child: Text(t))).toList(),
                                      ),
                                    );
                                    if (hours != null) setState(() => _counterHour = hours);
                                  },
                                  child: Text(_counterHour == null ? 'Choisir heure' : _counterHour!),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (_counterDate != null && _counterHour != null) {
                                      _submitClientAction('contre_proposer',);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisissez date et heure avant de proposer.')));
                                    }
                                  },
                                  child: const Text('Contre-proposer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (r.status == ReservationStatus.contrePropose)
                                  ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _submitClientAction('accepter');
                                    },
                                    child: const Text('Accepter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                OutlinedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _submitClientAction('annuler');
                                  },
                                  child: const Text('Annuler'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Summary + Envoyer (smart) aligned right
                            Row(
                              children: [
                                if (_counterDate != null || _counterHour != null)
                                  Expanded(child: Text('Proposition: ${_counterDate != null ? DateFormat('dd/MM/yyyy').format(_counterDate!) : ''} ${_counterHour ?? ''}')),
                                ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    // Smart send:
                                    if (_counterDate != null && _counterHour != null) {
                                      _submitClientAction('contre_proposer');
                                    } else if (r.status == ReservationStatus.contrePropose) {
                                      _submitClientAction('accepter');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisissez un créneau ou acceptez la proposition avant d\'envoyer.')));
                                    }
                                  },
                                  child: const Text('Envoyer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
