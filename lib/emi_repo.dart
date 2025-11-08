import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/emi_model.dart';

class EmiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Add EMI
  Future<int> addEmi(Emi emi) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.emisTable, emi.toMap());
  }

  // Update EMI
  Future<int> updateEmi(Emi emi) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.emisTable,
      emi.toMap(),
      where: '${DatabaseHelper.colEmiId} = ?',
      whereArgs: [emi.id],
    );
  }

  // Delete EMI
  Future<int> deleteEmi(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.emisTable,
      where: '${DatabaseHelper.colEmiId} = ?',
      whereArgs: [id],
    );
  }

  // Get All EMIs
  Future<List<Emi>> getAllEmis() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.emisTable,
      orderBy: '${DatabaseHelper.colNextDueDate} ASC',
    );
    return List.generate(maps.length, (i) {
      return Emi.fromMap(maps[i]);
    });
  }

  // Get All Active EMIs (tenure remaining > 0)
  Future<List<Emi>> getAllActiveEmis() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.emisTable,
      where: '${DatabaseHelper.colTenureRemainingMonths} > 0',
      orderBy: '${DatabaseHelper.colNextDueDate} ASC',
    );
    return List.generate(maps.length, (i) {
      return Emi.fromMap(maps[i]);
    });
  }

  // Get Upcoming EMIs (e.g., for dashboard)
  Future<List<Emi>> getUpcomingEmis({int limit = 3}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.emisTable,
      where: '${DatabaseHelper.colTenureRemainingMonths} > 0',
      orderBy: '${DatabaseHelper.colNextDueDate} ASC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return Emi.fromMap(maps[i]);
    });
  }

  // Get EMIs due this week
  Future<List<Emi>> getEmisDueThisWeek() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday + 1));
    final startTimestamp = now.millisecondsSinceEpoch;
    final endTimestamp = endOfWeek.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.emisTable,
      where:
          '${DatabaseHelper.colTenureRemainingMonths} > 0 AND ${DatabaseHelper.colNextDueDate} >= ? AND ${DatabaseHelper.colNextDueDate} <= ?',
      whereArgs: [startTimestamp, endTimestamp],
    );
    return List.generate(maps.length, (i) {
      return Emi.fromMap(maps[i]);
    });
  }

  // Mark EMI as Paid
  Future<Emi> markEmiAsPaid(Emi emi) async {
    if (emi.tenureRemainingMonths <= 0) {
      return emi; // Already paid off
    }

    final newTenureRemaining = emi.tenureRemainingMonths - 1;

    // Calculate next due date (add 1 month)
    final nextDueDate = DateTime(
      emi.nextDueDate.year,
      emi.nextDueDate.month + 1,
      emi.nextDueDate.day,
    );

    final updatedEmi = emi.copyWith(
      tenureRemainingMonths: newTenureRemaining,
      nextDueDate: nextDueDate,
    );

    await updateEmi(updatedEmi);

    // Return the updated EMI object
    return updatedEmi;
  }
}
