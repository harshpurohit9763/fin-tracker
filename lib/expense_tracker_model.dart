import 'package:personal_finance/category_model.dart';
import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/expense_model.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Add Expense
  Future<int> addExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.expensesTable, expense.toMap());
  }

  // Update Expense
  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.expensesTable,
      expense.toMap(),
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete Expense
  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.expensesTable,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  // Get All Expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.expensesTable,
      orderBy: '${DatabaseHelper.colDate} DESC',
    );
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Add Category
  Future<int> addCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.categoriesTable, category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Update Category
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.categoriesTable,
      category.toMap(),
      where: '${DatabaseHelper.colCatId} = ?',
      whereArgs: [category.id],
    );
  }

  // Delete Category
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.categoriesTable,
      where: '${DatabaseHelper.colCatId} = ?',
      whereArgs: [id],
    );
  }

  // Get All Categories
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.categoriesTable,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }
}
