class Enquiry {
  final int? id;
  final String enquiryNumber; // e.g. ENQ-001
  final int? customerId;
  final String customerName;
  final String phone;
  final String? email;
  final String eventType;
  final int guests;
  final DateTime preferredDate;
  final String preferredTime; // e.g. "10:00 AM - 5:00 PM"
  final String? startTime; // "10:00"
  final String? endTime; // "17:00"
  final int? preferredHallId;
  final String? preferredHallName;
  final double expectedBudget;
  final DateTime? followUpDate;
  final String status; // New, Contacted, Follow-up, Quotation Sent, Confirmed, Lost, Cancelled
  final String? notes;
  final int? convertedEventId; // Link to confirmed event
  final DateTime createdAt;
  final DateTime updatedAt;

  Enquiry({
    this.id,
    required this.enquiryNumber,
    this.customerId,
    required this.customerName,
    required this.phone,
    this.email,
    required this.eventType,
    required this.guests,
    required this.preferredDate,
    required this.preferredTime,
    this.startTime,
    this.endTime,
    this.preferredHallId,
    this.preferredHallName,
    required this.expectedBudget,
    this.followUpDate,
    this.status = 'New',
    this.notes,
    this.convertedEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isConverted => convertedEventId != null || status.toLowerCase() == 'confirmed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enquiry_number': enquiryNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'phone': phone,
      'email': email,
      'event_type': eventType,
      'guests': guests,
      'preferred_date': preferredDate.toIso8601String(),
      'preferred_time': preferredTime,
      'start_time': startTime,
      'end_time': endTime,
      'preferred_hall_id': preferredHallId,
      'preferred_hall_name': preferredHallName,
      'expected_budget': expectedBudget,
      'follow_up_date': followUpDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'converted_event_id': convertedEventId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Enquiry.fromMap(Map<String, dynamic> map) {
    return Enquiry(
      id: map['id'] as int?,
      enquiryNumber: map['enquiry_number'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      eventType: map['event_type'] as String,
      guests: map['guests'] as int,
      preferredDate: DateTime.parse(map['preferred_date'] as String),
      preferredTime: map['preferred_time'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      preferredHallId: map['preferred_hall_id'] as int?,
      preferredHallName: map['preferred_hall_name'] as String?,
      expectedBudget: (map['expected_budget'] as num).toDouble(),
      followUpDate: map['follow_up_date'] != null
          ? DateTime.parse(map['follow_up_date'] as String)
          : null,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      convertedEventId: map['converted_event_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Enquiry copyWith({
    int? id,
    String? enquiryNumber,
    int? customerId,
    String? customerName,
    String? phone,
    String? email,
    String? eventType,
    int? guests,
    DateTime? preferredDate,
    String? preferredTime,
    String? startTime,
    String? endTime,
    int? preferredHallId,
    String? preferredHallName,
    double? expectedBudget,
    DateTime? followUpDate,
    String? status,
    String? notes,
    int? convertedEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Enquiry(
      id: id ?? this.id,
      enquiryNumber: enquiryNumber ?? this.enquiryNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      eventType: eventType ?? this.eventType,
      guests: guests ?? this.guests,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      preferredHallId: preferredHallId ?? this.preferredHallId,
      preferredHallName: preferredHallName ?? this.preferredHallName,
      expectedBudget: expectedBudget ?? this.expectedBudget,
      followUpDate: followUpDate ?? this.followUpDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      convertedEventId: convertedEventId ?? this.convertedEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

