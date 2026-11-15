import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/customer.dart';

class CustomerRepository {
  Future<List<Customer>> getAllCustomers({String? searchQuery}) async {
    final db = await AppDatabase.instance.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause = 'name LIKE ? OR phone LIKE ? OR email LIKE ?';
      final q = '%${searchQuery.trim()}%';
      whereArgs = [q, q, q];
    }

    final result = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }
    return null;
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}

