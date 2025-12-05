import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import java.io.Directory;

class DatabaseHelper {
  // Table and column names
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 5;

  // Expenses Table
  static const String expensesTable = 'expenses';
  static const String colId = 'id';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colDate = 'date'; // Unix Timestamp
  static const String colMonthYear = 'month_year'; // "YYYY-MM"
  static const String colDescription = 'description';
  static const String colScheduledAmount = 'scheduled_amount';
  static const String colTransactionType = 'transaction_type';

  // Income Table
  static const String incomeTable = 'income';
  static const String colIncomeId = 'id';
  static const String colIncomeAmount = 'amount';
  static const String colIncomeDescription = 'description';
  static const String colIncomeSource =
      'source'; // New column for income source
  static const String colIncomeDate = 'date'; // Unix Timestamp
  static const String colIncomeMonthYear = 'month_year'; // "YYYY-MM"
  static const String colIncomeIsMonthly =
      'is_monthly'; // 0 for false, 1 for true

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

  // Goals Table
  static const String goalsTable = 'goals';
  static const String colGoalName = 'name';
  static const String colTargetAmount = 'targetAmount';
  static const String colCurrentAmount = 'currentAmount';
  static const String colTargetDate = 'targetDate';
  static const String colIcon = 'icon';

  // Badges Table
  static const String badgesTable = 'badges';
  static const String colBadgeGoalName = 'goal_name';
  static const String colBadgeGoalIcon = 'goal_icon';
  static const String colBadgeTargetAmount = 'target_amount';
  static const String colBadgeCompletionDate = 'completion_date';
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
      onUpgrade: _onUpgrade, // Add onUpgrade callback
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from version 1 to 2
      await db.execute(
          'ALTER TABLE $incomeTable ADD COLUMN $colIncomeSource TEXT;');
    }
    if (oldVersion < 3) {
      // Migrate from version 2 to 3
      await db.execute(
          'ALTER TABLE $expensesTable ADD COLUMN $colScheduledAmount REAL;');
      await db.execute(
          'ALTER TABLE $expensesTable ADD COLUMN $colTransactionType TEXT;');
    }
    if (oldVersion < 4) {
      // Migrate from version 3 to 4
      await _createGoalsTable(db);
    }
    if (oldVersion < 5) {
      // Migrate from version 4 to 5
      await _createBadgesTable(db);
    }
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
        $colDescription TEXT,
        $colScheduledAmount REAL,
        $colTransactionType TEXT
      )
    ''');

    // Create Income Table
    await db.execute('''
      CREATE TABLE $incomeTable (
        $colIncomeId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colIncomeAmount REAL NOT NULL,
        $colIncomeDescription TEXT,
        $colIncomeSource TEXT,
        $colIncomeDate INTEGER NOT NULL,
        $colIncomeMonthYear TEXT NOT NULL,
        $colIncomeIsMonthly INTEGER NOT NULL DEFAULT 0
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

    // Create Goals Table
    await _createGoalsTable(db);

    // Create Badges Table
    await _createBadgesTable(db);
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

  Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $goalsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colGoalName TEXT NOT NULL,
        $colTargetAmount REAL NOT NULL,
        $colCurrentAmount REAL NOT NULL,
        $colTargetDate INTEGER NOT NULL,
        $colIcon TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createBadgesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $badgesTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBadgeGoalName TEXT NOT NULL,
        $colBadgeGoalIcon TEXT NOT NULL,
        $colBadgeTargetAmount REAL NOT NULL,
        $colBadgeCompletionDate INTEGER NOT NULL
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
