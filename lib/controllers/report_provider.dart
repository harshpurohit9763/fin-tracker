import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/helper/report_repo.dart';

// Provides the repository instance
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// Defines the type of date range for the report
enum ReportDateRangeType {
  last7Days,
  last30Days,
  thisMonth,
  custom,
  monthly,
  selectedMonthYear
}

// Holds the currently selected date range type
final reportDateRangeTypeProvider =
    StateProvider<ReportDateRangeType>((ref) => ReportDateRangeType.thisMonth);

// Holds the custom date range if selected
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Holds the selected month for filtering transactions
final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

// Holds the selected year for filtering transactions
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// Pagination state for transactions
final transactionOffsetProvider = StateProvider<int>((ref) => 0);
final transactionLimitProvider = StateProvider<int>((ref) => 20);

// Provider for Category Breakdown data
final categoryBreakdownProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getCategoryBreakdown(range.start, range.end);
});

// Provider for Weekly Trend data
final dailyTrendProvider =
    FutureProvider.autoDispose<Map<DateTime, double>>((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getDailySpending(range.start, range.end);
});

// Provider for the total of the selected month
final selectedRangeTotalProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getTotalForDateRange(range.start, range.end);
});

// Provider for monthly breakdown data
final monthlyBreakdownProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getMonthlySpendingForRange(range.start, range.end);
});

// A derived provider that computes the current DateTimeRange based on the selected type
final currentDateRangeProvider = Provider<DateTimeRange>((ref) {
  final type = ref.watch(reportDateRangeTypeProvider);
  final now = DateTime.now();
  switch (type) {
    case ReportDateRangeType.last7Days:
      return DateTimeRange(
          start: now.subtract(const Duration(days: 6)), end: now);
    case ReportDateRangeType.last30Days:
      return DateTimeRange(
          start: now.subtract(const Duration(days: 29)), end: now);
    case ReportDateRangeType.custom:
      return ref.watch(customDateRangeProvider) ??
          DateTimeRange(start: now, end: now);
    case ReportDateRangeType.monthly:
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      return DateTimeRange(start: sixMonthsAgo, end: now);
    case ReportDateRangeType.selectedMonthYear:
      final selectedMonth = ref.watch(selectedMonthProvider);
      final selectedYear = ref.watch(selectedYearProvider);
      final firstDayOfSelectedMonth = DateTime(selectedYear, selectedMonth, 1);
      final lastDayOfSelectedMonth =
          DateTime(selectedYear, selectedMonth + 1, 0);
      return DateTimeRange(
          start: firstDayOfSelectedMonth, end: lastDayOfSelectedMonth);
    case ReportDateRangeType.thisMonth:
    default:
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
  }
});

// A provider that returns a filtered list of expenses based on the current date range and pagination
final filteredExpensesProvider = FutureProvider.autoDispose((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final offset = ref.watch(transactionOffsetProvider);
  final limit = ref.watch(transactionLimitProvider);
  final repository = ref.watch(reportRepositoryProvider);

  return repository.getExpensesPaginated(range.start, range.end, limit, offset);
});

// A provider that returns a filtered list of incomes based on the current date range and pagination
final filteredIncomeProvider =
    FutureProvider.autoDispose<List<Income>>((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final offset = ref.watch(transactionOffsetProvider);
  final limit = ref.watch(transactionLimitProvider);
  final repository = ref.watch(reportRepositoryProvider);

  return repository.getIncomesPaginated(range.start, range.end, limit, offset);
});

// A provider that returns all expenses for a given date range for the report
final allExpensesForReportProvider = FutureProvider.autoDispose((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final repository = ref.watch(reportRepositoryProvider);

  return repository.getAllExpensesForReport(range.start, range.end);
});

// A provider that returns all incomes for a given date range for the report
final allIncomesForReportProvider =
    FutureProvider.autoDispose<List<Income>>((ref) async {
  final range = ref.watch(currentDateRangeProvider);
  final repository = ref.watch(reportRepositoryProvider);

  return repository.getAllIncomesForReport(range.start, range.end);
});
