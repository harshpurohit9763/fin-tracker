import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/views/badge_model.dart';

class BadgeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Badge>> getAllBadges() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.badgesTable,
      orderBy: '${DatabaseHelper.colBadgeCompletionDate} DESC',
    );
    return List.generate(maps.length, (i) {
      return Badge.fromMap(maps[i]);
    });
  }

  Future<int> addBadge(Badge badge) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.badgesTable, badge.toMap());
  }
}
