import '../database/app_database.dart';
import '../models/hall.dart';
import '../models/hall_hold.dart';
import '../../core/utils/date_formatters.dart';

class HallAvailabilityResult {
  final bool isAvailable;
  final String? conflictReason;
  final String? conflictingEventNumber;

  HallAvailabilityResult({
    required this.isAvailable,
    this.conflictReason,
    this.conflictingEventNumber,
  });
}

class HallRepository {
  Future<List<Hall>> getAllHalls({bool activeOnly = false}) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'halls',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name ASC',
    );
    return result.map((map) => Hall.fromMap(map)).toList();
  }

  Future<Hall?> getHallById(int id) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('halls', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isNotEmpty) {
      return Hall.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertHall(Hall hall) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('halls', hall.toMap());
  }

  Future<int> updateHall(Hall hall) async {
    final db = await AppDatabase.instance.database;
    return await db.update('halls', hall.toMap(), where: 'id = ?', whereArgs: [hall.id]);
  }

  Future<int> deleteHall(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('halls', where: 'id = ?', whereArgs: [id]);
  }

  /// Checks if a hall is available on a specific date and time slot
  /// Prevents double bookings while allowing different halls on the same date.
  Future<HallAvailabilityResult> checkAvailability({
    required int hallId,
    required DateTime date,
    required String startTime,
    required String endTime,
    int? excludeEventId,
  }) async {
    final db = await AppDatabase.instance.database;
    final dateStr = DateFormatters.formatIsoDate(date);

    // 1. Check confirmed/in-progress events
    String query = '''
      SELECT * FROM events 
      WHERE hall_id = ? 
        AND event_date LIKE ? 
        AND status IN ('Confirmed', 'In-Progress')
    ''';
    List<dynamic> args = [hallId, '$dateStr%'];

    if (excludeEventId != null) {
      query += ' AND id != ?';
      args.add(excludeEventId);
    }

    final conflictingEvents = await db.rawQuery(query, args);
    if (conflictingEvents.isNotEmpty) {
      final conflict = conflictingEvents.first;
      return HallAvailabilityResult(
        isAvailable: false,
        conflictReason: 'Hall is already booked for "${conflict['event_type']}" (${conflict['start_time']} - ${conflict['end_time']})',
        conflictingEventNumber: conflict['event_number'] as String?,
      );
    }

    // 2. Check active temporary holds
    final nowIso = DateTime.now().toIso8601String();
    final conflictingHolds = await db.rawQuery('''
      SELECT * FROM hall_holds
      WHERE hall_id = ?
        AND hold_date LIKE ?
        AND status = 'Active'
        AND expires_at > ?
    ''', [hallId, '$dateStr%', nowIso]);

    if (conflictingHolds.isNotEmpty) {
      final hold = conflictingHolds.first;
      return HallAvailabilityResult(
        isAvailable: false,
        conflictReason: 'Hall has a temporary hold for: ${hold['reason']}',
      );
    }

    return HallAvailabilityResult(isAvailable: true);
  }

  // Hall holds
  Future<int> createHold(HallHold hold) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('hall_holds', hold.toMap());
  }

  Future<List<HallHold>> getActiveHoldsForDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = DateFormatters.formatIsoDate(date);
    final nowIso = DateTime.now().toIso8601String();

    final result = await db.query(
      'hall_holds',
      where: 'hold_date LIKE ? AND status = ? AND expires_at > ?',
      whereArgs: ['$dateStr%', 'Active', nowIso],
    );
    return result.map((map) => HallHold.fromMap(map)).toList();
  }
}

