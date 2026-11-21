import '../database/app_database.dart';
import '../models/payment.dart';
import '../../core/utils/date_formatters.dart';

class PaymentRepository {
  Future<List<Payment>> getPaymentsForEvent(int eventId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'payments',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'payment_date DESC',
    );
    return result.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllPaymentsDetailed({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await AppDatabase.instance.database;
    String query = '''
      SELECT p.*, e.event_number, e.customer_name, e.event_type, e.hall_name 
      FROM payments p
      JOIN events e ON p.event_id = e.id
    ''';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      final startStr = DateFormatters.formatIsoDate(startDate);
      final endStr = DateFormatters.formatIsoDate(endDate);
      query += ' WHERE p.payment_date >= ? AND p.payment_date <= ?';
      args.addAll(['$startStr 00:00:00', '$endStr 23:59:59']);
    }

    query += ' ORDER BY p.payment_date DESC';
    return await db.rawQuery(query, args);
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('payments', payment.toMap());

    // Update event advance_paid & balance_due
    await _updateEventBalance(payment.eventId);
    return id;
  }

  Future<int> deletePayment(int paymentId, int eventId) async {
    final db = await AppDatabase.instance.database;
    final count = await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
    await _updateEventBalance(eventId);
    return count;
  }

  Future<void> _updateEventBalance(int eventId) async {
    final db = await AppDatabase.instance.database;
    final payments = await db.rawQuery(
      'SELECT SUM(amount) as total_paid FROM payments WHERE event_id = ?',
      [eventId],
    );
    final totalPaid = (payments.first['total_paid'] as num?)?.toDouble() ?? 0.0;

    final eventRes = await db.query('events', where: 'id = ?', whereArgs: [eventId], limit: 1);
    if (eventRes.isNotEmpty) {
      final totalCost = (eventRes.first['total_cost'] as num).toDouble();
      final balanceDue = (totalCost - totalPaid).clamp(0.0, double.infinity);
      await db.update(
        'events',
        {
          'advance_paid': totalPaid,
          'balance_due': balanceDue,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [eventId],
      );
    }
  }

  Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate}) async {
    final db = await AppDatabase.instance.database;
    String query = 'SELECT SUM(amount) as total FROM payments';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      final startStr = DateFormatters.formatIsoDate(startDate);
      final endStr = DateFormatters.formatIsoDate(endDate);
      query += ' WHERE payment_date >= ? AND payment_date <= ?';
      args.addAll(['$startStr 00:00:00', '$endStr 23:59:59']);
    }

    final res = await db.rawQuery(query, args);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalPendingBalances() async {
    final db = await AppDatabase.instance.database;
    final res = await db.rawQuery('''
      SELECT SUM(balance_due) as total 
      FROM events 
      WHERE status IN ('Confirmed', 'In-Progress')
    ''');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

