import '../database/app_database.dart';
import '../models/event_booking.dart';
import '../../core/utils/date_formatters.dart';

class EventRepository {
  Future<String> generateNextEventNumber() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT event_number FROM events ORDER BY id DESC LIMIT 1',
    );
    if (result.isEmpty) {
      return 'EVT-001';
    }
    final lastNumStr = result.first['event_number'] as String;
    final numPart = int.tryParse(lastNumStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final nextNum = numPart + 1;
    return 'EVT-${nextNum.toString().padLeft(3, '0')}';
  }

  Future<List<EventBooking>> getEvents({
    String? searchQuery,
    String? statusFilter,
    int? hallIdFilter,
    DateTime? dateFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await AppDatabase.instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(customer_name LIKE ? OR phone LIKE ? OR event_number LIKE ? OR event_type LIKE ?)');
      whereArgs.addAll([q, q, q, q]);
    }

    if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(statusFilter);
    }

    if (hallIdFilter != null && hallIdFilter > 0) {
      whereClauses.add('hall_id = ?');
      whereArgs.add(hallIdFilter);
    }

    if (dateFilter != null) {
      final dateStr = DateFormatters.formatIsoDate(dateFilter);
      whereClauses.add('event_date LIKE ?');
      whereArgs.add('$dateStr%');
    } else if (startDate != null && endDate != null) {
      final startStr = DateFormatters.formatIsoDate(startDate);
      final endStr = DateFormatters.formatIsoDate(endDate);
      whereClauses.add('event_date >= ? AND event_date <= ?');
      whereArgs.addAll(['$startStr 00:00:00', '$endStr 23:59:59']);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'events',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'event_date ASC, start_time ASC',
    );

    return result.map((map) => EventBooking.fromMap(map)).toList();
  }

  Future<EventBooking?> getEventById(int id) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('events', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isNotEmpty) {
      return EventBooking.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertEvent(EventBooking event) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('events', event.toMap());
  }

  Future<int> updateEvent(EventBooking event) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> cancelEvent(int id, {String? reason}) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'events',
      {
        'status': 'Cancelled',
        'notes': reason != null ? 'Cancelled: $reason' : 'Cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recalculateBalances(int eventId) async {
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
}

