import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/enquiry.dart';
import '../models/follow_up.dart';
import '../models/event_booking.dart';
import '../models/payment.dart';
import '../../core/utils/date_formatters.dart';

class EnquiryRepository {
  Future<String> generateNextEnquiryNumber() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT enquiry_number FROM enquiries ORDER BY id DESC LIMIT 1',
    );
    if (result.isEmpty) {
      return 'ENQ-001';
    }
    final lastNumStr = result.first['enquiry_number'] as String;
    final numPart = int.tryParse(lastNumStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final nextNum = numPart + 1;
    return 'ENQ-${nextNum.toString().padLeft(3, '0')}';
  }

  Future<List<Enquiry>> getEnquiries({
    String? searchQuery,
    String? statusFilter,
    DateTime? dateFilter,
  }) async {
    final db = await AppDatabase.instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(customer_name LIKE ? OR phone LIKE ? OR enquiry_number LIKE ?)');
      whereArgs.addAll([q, q, q]);
    }

    if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(statusFilter);
    }

    if (dateFilter != null) {
      final dateStr = DateFormatters.formatIsoDate(dateFilter);
      whereClauses.add('preferred_date LIKE ?');
      whereArgs.add('$dateStr%');
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'enquiries',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return result.map((map) => Enquiry.fromMap(map)).toList();
  }

  Future<Enquiry?> getEnquiryById(int id) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('enquiries', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isNotEmpty) {
      return Enquiry.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertEnquiry(Enquiry enquiry) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('enquiries', enquiry.toMap());
  }

  Future<int> updateEnquiry(Enquiry enquiry) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'enquiries',
      enquiry.toMap(),
      where: 'id = ?',
      whereArgs: [enquiry.id],
    );
  }

  Future<int> deleteEnquiry(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('enquiries', where: 'id = ?', whereArgs: [id]);
  }

  // Follow-up history
  Future<int> addFollowUp(FollowUp followUp) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('follow_ups', followUp.toMap());

    // Update the enquiry status & follow up date
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (followUp.newStatus != null) {
      updates['status'] = followUp.newStatus!;
    }
    if (followUp.nextFollowUpDate != null) {
      updates['follow_up_date'] = followUp.nextFollowUpDate!.toIso8601String();
    }
    await db.update(
      'enquiries',
      updates,
      where: 'id = ?',
      whereArgs: [followUp.enquiryId],
    );

    return id;
  }

  Future<List<FollowUp>> getFollowUpsForEnquiry(int enquiryId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'follow_ups',
      where: 'enquiry_id = ?',
      whereArgs: [enquiryId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => FollowUp.fromMap(map)).toList();
  }

  /// Get follow up reminders due on or before a given date
  Future<List<Enquiry>> getFollowUpReminders({DateTime? date}) async {
    final db = await AppDatabase.instance.database;
    final targetDate = date ?? DateTime.now();
    final dateStr = DateFormatters.formatIsoDate(targetDate);

    final result = await db.query(
      'enquiries',
      where: 'follow_up_date LIKE ? AND status NOT IN (?, ?, ?)',
      whereArgs: ['$dateStr%', 'Confirmed', 'Lost', 'Cancelled'],
      orderBy: 'follow_up_date ASC',
    );
    return result.map((map) => Enquiry.fromMap(map)).toList();
  }

  /// Convert Enquiry into Confirmed Event
  /// Retains the original enquiry history, prevents duplicate conversion,
  /// updates status, creates the event, and records advance payment if provided.
  Future<EventBooking> convertEnquiryToBooking({
    required Enquiry enquiry,
    required EventBooking eventData,
    double? initialAdvance,
    String? paymentMethod,
  }) async {
    final db = await AppDatabase.instance.database;

    return await db.transaction<EventBooking>((txn) async {
      // 1. Verify not already converted
      if (enquiry.convertedEventId != null) {
        throw Exception('This enquiry has already been converted to Event #${enquiry.convertedEventId}.');
      }

      // 2. Insert the event
      final eventId = await txn.insert('events', eventData.toMap());
      final createdEvent = eventData.copyWith(id: eventId);

      // 3. If an initial advance was paid, insert payment record
      if (initialAdvance != null && initialAdvance > 0) {
        final payment = Payment(
          eventId: eventId,
          customerId: eventData.customerId,
          amount: initialAdvance,
          paymentType: 'Advance',
          paymentMethod: paymentMethod ?? 'Cash',
          paymentDate: DateTime.now(),
          notes: 'Advance paid during enquiry conversion (Enquiry ${enquiry.enquiryNumber})',
        );
        await txn.insert('payments', payment.toMap());
      }

      // 4. Update the enquiry record
      await txn.update(
        'enquiries',
        {
          'status': 'Confirmed',
          'converted_event_id': eventId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [enquiry.id],
      );

      // 5. Add a follow-up record tracking the conversion
      final conversionNote = FollowUp(
        enquiryId: enquiry.id!,
        note: 'Enquiry successfully converted to Event ${createdEvent.eventNumber}. Hall: ${createdEvent.hallName}, Total: ₹${createdEvent.totalCost.toStringAsFixed(0)}',
        oldStatus: enquiry.status,
        newStatus: 'Confirmed',
        createdAt: DateTime.now(),
      );
      await txn.insert('follow_ups', conversionNote.toMap());

      return createdEvent;
    });
  }
}

