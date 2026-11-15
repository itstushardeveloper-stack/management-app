class Payment {
  final int? id;
  final int eventId;
  final int? customerId;
  final double amount;
  final String paymentType; // Advance, Part Payment, Final Balance, Deposit
  final String paymentMethod; // Cash, UPI/Online, Card, Cheque, Bank Transfer
  final DateTime paymentDate;
  final String? transactionRef;
  final String? notes;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.eventId,
    this.customerId,
    required this.amount,
    required this.paymentType,
    required this.paymentMethod,
    required this.paymentDate,
    this.transactionRef,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'customer_id': customerId,
      'amount': amount,
      'payment_type': paymentType,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'transaction_ref': transactionRef,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      customerId: map['customer_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      paymentType: map['payment_type'] as String,
      paymentMethod: map['payment_method'] as String,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      transactionRef: map['transaction_ref'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

