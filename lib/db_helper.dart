import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import java.io.Directory;

class DatabaseHelper {
  // Table and column names
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;

  // Expenses Table
  static const String expensesTable = 'expenses';
  static const String colId = 'id';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colDate = 'date'; // Unix Timestamp
  static const String colMonthYear = 'month_year'; // "YYYY-MM"
  static const String colDescription = 'description';

  // Categories Table
  static const String categoriesTable = 'categories';
  static const String colCatId = 'id';
  static const String colCatName = 'name';
  static const String colCatType = 'type'; // New column for Need/Want

  // EMIs Table
  static const String emisTable = 'emis';
  static const String colEmiId = 'id';
  static const String colLoanName = 'loan_name';
  static const String colBankName = 'bank_name';
  static const String colMonthlyEmiAmount = 'monthly_emi_amount';
  static const String colInterestRate = 'interest_rate';
  static const String colTotalTenureMonths = 'total_tenure_months';
  static const String colTenureRemainingMonths = 'tenure_remaining_months';
  static const String colNextDueDate = 'next_due_date'; // Unix Timestamp

  // Budgets Table
  static const String budgetsTable = 'budgets';
  static const String colBudgetId = 'id';
  static const String colBudgetCategory = 'category_name';
  static const String colBudgetAmount = 'amount';
  static const String colBudgetMonthYear = 'month_year';

  // Assets Table
  static const String assetsTable = 'assets';
  static const String colAssetId = 'id';
  static const String colAssetName = 'name';
  static const String colAssetValue = 'value';
  static const String colAssetYearlyAppreciation =
      'yearly_appreciation'; // New column
  static const String colAssetIcon = 'icon';

  // Subscriptions Table
  static const String subscriptionsTable = 'subscriptions';
  static const String colSubId = 'id';
  static const String colSubName = 'name';
  static const String colSubAmount = 'amount';
  static const String colSubNextDueDate = 'next_due_date';
  static const String colSubIcon = 'icon';
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Expenses Table
    await db.execute('''
      CREATE TABLE $expensesTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colAmount REAL NOT NULL,
        $colCategory TEXT NOT NULL,
        $colDate INTEGER NOT NULL,
        $colMonthYear TEXT NOT NULL,
        $colDescription TEXT
      )
    ''');

    // Create Categories Table
    await db.execute('''
      CREATE TABLE $categoriesTable (
        $colCatId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colCatName TEXT NOT NULL UNIQUE,
        $colCatType TEXT NOT NULL DEFAULT 'Want'
      )
    ''');

    // Create EMIs Table
    await db.execute('''
      CREATE TABLE $emisTable (
        $colEmiId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colLoanName TEXT NOT NULL,
        $colBankName TEXT,
        $colMonthlyEmiAmount REAL NOT NULL,
        $colInterestRate REAL,
        $colTotalTenureMonths INTEGER NOT NULL,
        $colTenureRemainingMonths INTEGER NOT NULL,
        $colNextDueDate INTEGER NOT NULL
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);

    // Create Budgets Table
    await _createBudgetsTable(db);

    // Create Assets Table
    await _createAssetsTable(db);

    // Create Subscriptions Table
    await _createSubscriptionsTable(db);
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $budgetsTable (
        $colBudgetId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBudgetCategory TEXT NOT NULL,
        $colBudgetAmount REAL NOT NULL,
        $colBudgetMonthYear TEXT NOT NULL,
        UNIQUE($colBudgetCategory, $colBudgetMonthYear)
      )
    ''');
  }

  Future<void> _createAssetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $assetsTable (
        $colAssetId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colAssetName TEXT NOT NULL,
        $colAssetValue REAL NOT NULL,
        $colAssetYearlyAppreciation REAL,
        $colAssetIcon TEXT
      )
    ''');
  }

  Future<void> _createSubscriptionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $subscriptionsTable (
        $colSubId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colSubName TEXT NOT NULL,
        $colSubAmount REAL NOT NULL,
        $colSubNextDueDate INTEGER NOT NULL,
        $colSubIcon TEXT
      )
    ''');
  }

  Future<void> _insertDefaultCategories(Database db) async {
    List<String> expenseCategories = [
      "Housing & Utilities",
      "Food & Groceries",
      "Transport & Commute",
      "Loans & Credit",
      "Personal & Miscellaneous",
      "Money Transfers / Gifts",
      "Household Purchases",
      "Small Items / Daily Essentials",
    ];
    for (String category in expenseCategories) {
      await db.insert(categoriesTable, {colCatName: category},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
