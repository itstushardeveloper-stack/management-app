class Expense {
  final int? id;
  final String title;
  final String category; // Maintenance, Catering, Utilities, Staff, Decoration, Taxes, Other
  final double amount;
  final DateTime expenseDate;
  final int? eventId; // Optional link to specific event
  final String? notes;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.eventId,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'event_id': eventId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(map['expense_date'] as String),
      eventId: map['event_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

