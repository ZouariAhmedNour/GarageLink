import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/reservation_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:garagelink/models/reservation.dart';

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  // Affichage agréable : dd/MM/yyyy et HH:mm
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFmt = DateFormat.Hm();

  @override
  void initState() {
    super.initState();
    // charge la liste après build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationsProvider.notifier).loadAll();
    });
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

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(reservationsProvider.notifier).loadAll();
  }

  Future<void> _performAction({
    required Reservation reservation,
    required String action,
    DateTime? newDate,
    String? newHeureDebut,
    String? message,
  }) async {
    final notifier = ref.read(reservationsProvider.notifier);
    try {
      HapticFeedback.lightImpact();
      await notifier.updateReservation(
        id: reservation.id ?? '',
        action: action,
        newDate: newDate,
        newHeureDebut: newHeureDebut,
        message: message,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action effectuée : $action')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _showProposeDialog(Reservation r) async {
    DateTime? pickedDate = r.creneauDemande.date ?? DateTime.now();
    TimeOfDay? pickedTime = r.creneauDemande.heureDebut != null
        ? _parseTimeOfDay(r.creneauDemande.heureDebut!)
        : TimeOfDay(hour: 9, minute: 0);

    final date = await showDatePicker(
      context: context,
      initialDate: pickedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: pickedTime ?? TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final heureStr = time.format(context);
    final dateIso = DateTime(date.year, date.month, date.day);

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer contre-proposition'),
        content: Text('Proposer le ${_dateFmt.format(dateIso)} à $heureStr ?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm == true) {
      await _performAction(
        reservation: r,
        action: 'contre_propose',
        newDate: dateIso,
        newHeureDebut: heureStr,
      );
    }
  }

  TimeOfDay? _parseTimeOfDay(String s) {
    try {
      final parts = s.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);
    final reservations = state.reservations;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Réservations', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF357ABD),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF357ABD),
        child: Builder(builder: (context) {
          if (state.loading) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.error != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(child: Text('Erreur: ${state.error}')),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    onPressed: _refresh,
                  ),
                ),
              ],
            );
          }
          if (reservations.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Aucune réservation', style: TextStyle(fontSize: 16))),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final r = reservations[idx];

              // date/time demandé
              final requestedDate = r.creneauDemande.date;
              final requestedDateStr = requestedDate != null ? _dateFmt.format(requestedDate.toLocal()) : 'Date non définie';
              final requestedTimeStr = r.creneauDemande.heureDebut ?? 'Heure non définie';

              // si un créneau proposé par le garage existe, on l'affiche aussi
              final proposed = r.creneauPropose;
              final proposedDateStr = proposed?.date != null ? _dateFmt.format(proposed!.date!.toLocal()) : null;
              final proposedTimeStr = proposed?.heureDebut;

              final serviceLabel = (r.serviceName != null && r.serviceName!.isNotEmpty) ? r.serviceName! : r.serviceId;
              final client = r.clientName.isNotEmpty ? r.clientName : r.clientPhone;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row with client, service and requested date/time
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_available, color: Color(0xFF357ABD)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // client / titre
                                Text(client,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                // ligne dédiée pour date + heure + service (évite overflow)
                                Row(
                                  children: [
                                    // service label (ellipsis)
                                    Expanded(
                                      child: Text(
                                        serviceLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // date
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                                        const SizedBox(width: 4),
                                        Text(requestedDateStr, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // heure
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.black45),
                                        const SizedBox(width: 4),
                                        Text(requestedTimeStr, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // statut
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(r.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_statusLabel(r.status),
                                    style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // affiche le créneau proposé (si présent) sous la header card
                      if (proposed != null && (proposedDateStr != null || proposedTimeStr != null))
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Proposé: ${proposedDateStr ?? ''} ${proposedTimeStr ?? ''}',
                                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // description: label first, then content
                      if (r.descriptionDepannage.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description :',
                              style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r.descriptionDepannage,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // actions: Wrap pour éviter overflow, Annuler aligné à droite
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (r.status == ReservationStatus.enAttente || r.status == ReservationStatus.contrePropose) ...[
                            OutlinedButton(
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Accepter la réservation'),
                                    content: const Text('Confirmer l\'acceptation ?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Non')),
                                      ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Oui')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _performAction(reservation: r, action: 'accepte');
                                }
                              },
                              child: const Text('Accepter'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Refuser la réservation'),
                                    content: const Text('Voulez-vous refuser cette réservation ?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Non')),
                                      ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Oui')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _performAction(reservation: r, action: 'refuse');
                                }
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Refuser'),
                            ),
                            OutlinedButton(
                              onPressed: () => _showProposeDialog(r),
                              child: const Text('Contre-proposer'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text('Annuler la réservation'),
                                content: const Text('Confirmer l\'annulation ?'),
                                actions: [
                                  TextButton(onPressed: () => Get.back(result: false), child: const Text('Non')),
                                  ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Oui')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _performAction(reservation: r, action: 'annule');
                            }
                          },
                          child: const Text('Annuler', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
