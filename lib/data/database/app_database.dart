import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('event_venue_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // If running on desktop (Windows, Linux, macOS), initialize sqflite_ffi
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationDocumentsDirectory();
      path = join(docDir.path, 'EventVenueManager', filePath);
      final dir = Directory(dirname(path));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Halls Table
    await db.execute('''
      CREATE TABLE halls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        base_price REAL NOT NULL,
        description TEXT,
        amenities TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. Enquiries Table
    await db.execute('''
      CREATE TABLE enquiries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        enquiry_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        event_type TEXT NOT NULL,
        guests INTEGER NOT NULL,
        preferred_date TEXT NOT NULL,
        preferred_time TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        preferred_hall_id INTEGER,
        preferred_hall_name TEXT,
        expected_budget REAL NOT NULL,
        follow_up_date TEXT,
        status TEXT NOT NULL DEFAULT 'New',
        notes TEXT,
        converted_event_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
        FOREIGN KEY (preferred_hall_id) REFERENCES halls (id) ON DELETE SET NULL
      )
    ''');

    // 4. Follow-up History Table
    await db.execute('''
      CREATE TABLE follow_ups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        enquiry_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        old_status TEXT,
        new_status TEXT,
        next_follow_up_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (enquiry_id) REFERENCES enquiries (id) ON DELETE CASCADE
      )
    ''');

    // 5. Hall Holds Table (Temporary holds with expiry)
    await db.execute('''
      CREATE TABLE hall_holds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hall_id INTEGER NOT NULL,
        enquiry_id INTEGER,
        hold_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        reason TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Active',
        created_at TEXT NOT NULL,
        FOREIGN KEY (hall_id) REFERENCES halls (id) ON DELETE CASCADE,
        FOREIGN KEY (enquiry_id) REFERENCES enquiries (id) ON DELETE SET NULL
      )
    ''');

    // 6. Confirmed Events Table
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_number TEXT NOT NULL UNIQUE,
        enquiry_id INTEGER,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        event_type TEXT NOT NULL,
        guests INTEGER NOT NULL,
        event_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        hall_id INTEGER NOT NULL,
        hall_name TEXT NOT NULL,
        total_cost REAL NOT NULL,
        advance_paid REAL NOT NULL DEFAULT 0.0,
        balance_due REAL NOT NULL,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'Confirmed',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (enquiry_id) REFERENCES enquiries (id) ON DELETE SET NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
        FOREIGN KEY (hall_id) REFERENCES halls (id) ON DELETE RESTRICT
      )
    ''');

    // 7. Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        customer_id INTEGER,
        amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        transaction_ref TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    // 8. Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        event_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE SET NULL
      )
    ''');

    // Indexes for fast lookup & calendar queries
    await db.execute('CREATE INDEX idx_events_date ON events (event_date)');
    await db.execute('CREATE INDEX idx_events_hall ON events (hall_id)');
    await db.execute('CREATE INDEX idx_enquiries_date ON enquiries (preferred_date)');
    await db.execute('CREATE INDEX idx_enquiries_follow_up ON enquiries (follow_up_date)');
    await db.execute('CREATE INDEX idx_enquiries_status ON enquiries (status)');
    await db.execute('CREATE INDEX idx_payments_event ON payments (event_id)');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

