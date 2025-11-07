import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/report_repo.dart';

// Provides the repository instance
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// Provider for the currently selected month in the reports screen
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider for Category Breakdown data
final categoryBreakdownProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final selectedDate = ref.watch(selectedMonthProvider);
  final monthYear = AppFormatters.formatMonthYear(selectedDate);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getCategoryBreakdown(monthYear);
});

// Provider for Weekly Trend data
final weeklyTrendProvider = FutureProvider.autoDispose<Map<int, double>>((
  ref,
) async {
  final selectedDate = ref.watch(selectedMonthProvider);
  final monthYear = AppFormatters.formatMonthYear(selectedDate);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getWeeklySpending(monthYear);
});

// Provider for the total of the selected month
final selectedMonthTotalProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final selectedDate = ref.watch(selectedMonthProvider);
  final monthYear = AppFormatters.formatMonthYear(selectedDate);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getTotalForMonth(monthYear);
});
