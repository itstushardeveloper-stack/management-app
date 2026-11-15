class FollowUp {
  final int? id;
  final int enquiryId;
  final String note;
  final String? oldStatus;
  final String? newStatus;
  final DateTime? nextFollowUpDate;
  final DateTime createdAt;

  FollowUp({
    this.id,
    required this.enquiryId,
    required this.note,
    this.oldStatus,
    this.newStatus,
    this.nextFollowUpDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enquiry_id': enquiryId,
      'note': note,
      'old_status': oldStatus,
      'new_status': newStatus,
      'next_follow_up_date': nextFollowUpDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FollowUp.fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'] as int?,
      enquiryId: map['enquiry_id'] as int,
      note: map['note'] as String,
      oldStatus: map['old_status'] as String?,
      newStatus: map['new_status'] as String?,
      nextFollowUpDate: map['next_follow_up_date'] != null
          ? DateTime.parse(map['next_follow_up_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

