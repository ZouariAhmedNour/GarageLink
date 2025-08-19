// models/order.dart
class WorkOrder {
  final String id;
  final String client;
  final String phone;
  final String email;
  final String mechanic;
  final String workshop;
  final DateTime date;
  final String status;
  final String vin; // Added VIN field
  final String service; // Added service field

  WorkOrder({
    required this.id,
    required this.client,
    required this.phone,
    required this.email,
    required this.mechanic,
    required this.workshop,
    required this.date,
    required this.status,
    required this.vin, // Added parameter
    required this.service, // Added parameter
  });

  WorkOrder copyWith({
    String? status,
    String? mechanic,
    String? workshop,
    DateTime? date,
    String? vin,
    String? service,
  }) {
    return WorkOrder(
      id: id,
      client: client,
      phone: phone,
      email: email,
      mechanic: mechanic ?? this.mechanic,
      workshop: workshop ?? this.workshop,
      date: date ?? this.date,
      status: status ?? this.status,
      vin: vin ?? this.vin, // Added vin parameter
      service: service ?? this.service, // Added service parameter
    );
  }
}