import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/budget_model.dart';
import 'package:personal_finance/controllers/budget_provider.dart';

import '../models/asset_model.dart';
import '../controllers/asset_provider.dart';
import '../models/category_model.dart';
import '../controllers/category_provider.dart';
import '../models/emi_model.dart';
import '../controllers/emi_provider.dart';
import '../models/expense_model.dart';
import '../controllers/expense_provider.dart';
import '../models/income_model.dart';
import '../controllers/income_provider.dart';
import '../models/subscription_model.dart';
import '../controllers/subscription_provider.dart';

class DummyDataService {
  final Ref ref;

  DummyDataService(this.ref);

  Future<void> populateDummyData() async {
    try {
      final String response = await rootBundle.loadString('assets/dummy.json');
      final data = json.decode(response);

      // Populate Categories
      if (data['categories'] != null) {
        for (var item in data['categories']) {
          final category = Category.fromMap(item);
          await ref.read(categoryListProvider.notifier).addCategory(category);
        }
      }

      // Populate Expenses
      if (data['expenses'] != null) {
        for (var item in data['expenses']) {
          final expense = Expense.fromMap(item);
          await ref.read(expenseListProvider.notifier).addExpense(expense);
        }
      }

      // Populate Incomes
      if (data['incomes'] != null) {
        for (var item in data['incomes']) {
          final income = Income.fromMap(item);
          await ref.read(incomeListProvider.notifier).addIncome(income);
        }
      }

      // Populate Assets
      if (data['assets'] != null) {
        for (var item in data['assets']) {
          final asset = Asset.fromMap(item);
          await ref.read(assetListProvider.notifier).addAsset(asset);
        }
      }

      // Populate EMIs
      if (data['emis'] != null) {
        for (var item in data['emis']) {
          final emi = Emi.fromMap(item);
          await ref.read(emiListProvider.notifier).addEmi(emi);
        }
      }

      // Populate Subscriptions
      if (data['subscriptions'] != null) {
        for (var item in data['subscriptions']) {
          final subscription = Subscription.fromMap(item);
          await ref
              .read(subscriptionListProvider.notifier)
              .addSubscription(subscription);
        }
      }

      // Populate Budgets
      if (data['budgets'] != null) {
        final budgetRepository = ref.read(budgetRepositoryProvider);
        for (var item in data['budgets']) {
          final budget = Budget.fromMap(item);
          await budgetRepository.upsertBudget(budget);
        }
      }

      print('Dummy data populated successfully!');
    } catch (e) {
      print('Error populating dummy data: $e');
    }
  }
}

final dummyDataServiceProvider = Provider((ref) => DummyDataService(ref));
