import '../database/app_database.dart';
import '../models/expense.dart';
import '../../core/utils/date_formatters.dart';

class ExpenseRepository {
  Future<List<Expense>> getAllExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await AppDatabase.instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (category != null && category != 'All' && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (startDate != null && endDate != null) {
      final startStr = DateFormatters.formatIsoDate(startDate);
      final endStr = DateFormatters.formatIsoDate(endDate);
      whereClauses.add('expense_date >= ? AND expense_date <= ?');
      whereArgs.addAll(['$startStr 00:00:00', '$endStr 23:59:59']);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'expenses',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'expense_date DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await AppDatabase.instance.database;
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    final db = await AppDatabase.instance.database;
    String query = 'SELECT SUM(amount) as total FROM expenses';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      final startStr = DateFormatters.formatIsoDate(startDate);
      final endStr = DateFormatters.formatIsoDate(endDate);
      query += ' WHERE expense_date >= ? AND expense_date <= ?';
      args.addAll(['$startStr 00:00:00', '$endStr 23:59:59']);
    }

    final res = await db.rawQuery(query, args);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

