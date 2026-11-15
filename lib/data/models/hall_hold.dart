class HallHold {
  final int? id;
  final int hallId;
  final int? enquiryId;
  final DateTime holdDate;
  final String startTime;
  final String endTime;
  final String reason;
  final DateTime expiresAt;
  final String status; // Active, Expired, Released, Converted
  final DateTime createdAt;

  HallHold({
    this.id,
    required this.hallId,
    this.enquiryId,
    required this.holdDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.expiresAt,
    this.status = 'Active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt) || status == 'Expired';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hall_id': hallId,
      'enquiry_id': enquiryId,
      'hold_date': holdDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HallHold.fromMap(Map<String, dynamic> map) {
    return HallHold(
      id: map['id'] as int?,
      hallId: map['hall_id'] as int,
      enquiryId: map['enquiry_id'] as int?,
      holdDate: DateTime.parse(map['hold_date'] as String),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      reason: map['reason'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

