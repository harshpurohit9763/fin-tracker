import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/views/goal_model.dart';

class GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Goal>> getAllGoals() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.goalsTable,
      orderBy: '${DatabaseHelper.colTargetDate} ASC',
    );
    return List.generate(maps.length, (i) {
      return Goal.fromMap(maps[i]);
    });
  }

  Future<int> addGoal(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.goalsTable, goal.toMap());
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.goalsTable,
      goal.toMap(),
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.goalsTable,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> contributeToGoal(int goalId, double amount) async {
    final db = await _dbHelper.database;
    // Use a transaction to ensure both operations succeed or fail together
    await db.transaction((txn) async {
      // Get the current amount
      final List<Map<String, dynamic>> result = await txn.query(
        DatabaseHelper.goalsTable,
        columns: [DatabaseHelper.colCurrentAmount],
        where: '${DatabaseHelper.colId} = ?',
        whereArgs: [goalId],
      );
      final double currentAmount =
          result.first[DatabaseHelper.colCurrentAmount];
      final double newAmount = currentAmount + amount;

      await txn.update(DatabaseHelper.goalsTable,
          {DatabaseHelper.colCurrentAmount: newAmount},
          where: '${DatabaseHelper.colId} = ?', whereArgs: [goalId]);
    });
  }
}
