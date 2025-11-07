import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/report_repo.dart';

// Provides the repository instance
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// Defines the type of date range for the report
enum ReportDateRangeType { last7Days, last30Days, thisMonth, custom }

// Holds the currently selected date range type
final reportDateRangeTypeProvider =
    StateProvider<ReportDateRangeType>((ref) => ReportDateRangeType.thisMonth);

// Holds the custom date range if selected
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

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
    case ReportDateRangeType.thisMonth:
    default:
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
  }
});
