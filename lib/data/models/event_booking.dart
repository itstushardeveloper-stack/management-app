class EventBooking {
  final int? id;
  final String eventNumber; // e.g. EVT-001
  final int? enquiryId; // Link to original enquiry
  final int? customerId;
  final String customerName;
  final String phone;
  final String? email;
  final String eventType;
  final int guests;
  final DateTime eventDate;
  final String startTime; // e.g. "10:00 AM"
  final String endTime; // e.g. "05:00 PM"
  final int hallId;
  final String hallName;
  final double totalCost;
  final double advancePaid;
  final double balanceDue;
  final String? notes;
  final String status; // Confirmed, In-Progress, Completed, Cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  EventBooking({
    this.id,
    required this.eventNumber,
    this.enquiryId,
    this.customerId,
    required this.customerName,
    required this.phone,
    this.email,
    required this.eventType,
    required this.guests,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.hallId,
    required this.hallName,
    required this.totalCost,
    required this.advancePaid,
    required this.balanceDue,
    this.notes,
    this.status = 'Confirmed',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_number': eventNumber,
      'enquiry_id': enquiryId,
      'customer_id': customerId,
      'customer_name': customerName,
      'phone': phone,
      'email': email,
      'event_type': eventType,
      'guests': guests,
      'event_date': eventDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'hall_id': hallId,
      'hall_name': hallName,
      'total_cost': totalCost,
      'advance_paid': advancePaid,
      'balance_due': balanceDue,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EventBooking.fromMap(Map<String, dynamic> map) {
    return EventBooking(
      id: map['id'] as int?,
      eventNumber: map['event_number'] as String,
      enquiryId: map['enquiry_id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      eventType: map['event_type'] as String,
      guests: map['guests'] as int,
      eventDate: DateTime.parse(map['event_date'] as String),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      hallId: map['hall_id'] as int,
      hallName: map['hall_name'] as String,
      totalCost: (map['total_cost'] as num).toDouble(),
      advancePaid: (map['advance_paid'] as num).toDouble(),
      balanceDue: (map['balance_due'] as num).toDouble(),
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  EventBooking copyWith({
    int? id,
    String? eventNumber,
    int? enquiryId,
    int? customerId,
    String? customerName,
    String? phone,
    String? email,
    String? eventType,
    int? guests,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    int? hallId,
    String? hallName,
    double? totalCost,
    double? advancePaid,
    double? balanceDue,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventBooking(
      id: id ?? this.id,
      eventNumber: eventNumber ?? this.eventNumber,
      enquiryId: enquiryId ?? this.enquiryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      eventType: eventType ?? this.eventType,
      guests: guests ?? this.guests,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      totalCost: totalCost ?? this.totalCost,
      advancePaid: advancePaid ?? this.advancePaid,
      balanceDue: balanceDue ?? this.balanceDue,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

