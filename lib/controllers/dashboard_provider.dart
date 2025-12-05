import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/helper/emi_repo.dart';
import 'package:personal_finance/helper/report_repo.dart';

// Provides the repository instances
final _reportRepo = Provider((ref) => ReportRepository());
final _emiRepo = Provider((ref) => EmiRepository());

// Provider for Current Month's Total Spending
final currentMonthSpendingProvider = FutureProvider<double>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  // Exclude 'Investment' type transactions to get true spending
  return await ref.watch(_reportRepo).getTotalForDateRangeFiltered(
      startOfMonth, endOfMonth,
      excludedTypes: ['Investment']);
});

// Provider for savings/investments made in the current month.
final currentMonthSavingsProvider = FutureProvider<double>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  // Only include 'Investment' type transactions
  return await ref.watch(_reportRepo).getTotalForDateRangeFiltered(
      startOfMonth, endOfMonth,
      includedTypes: ['Investment']);
});

// Provider for Upcoming EMIs Due This Week (Count)
final upcomingEmisThisWeekCountProvider = FutureProvider<int>((ref) async {
  final emis = await ref.watch(_emiRepo).getEmisDueThisWeek();
  return emis.length;
});

// Provider for Last 6 Months Spending Trend
final last6MonthsSpendingProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  return ref.watch(_reportRepo).getLast6MonthsSpending();
});

// Provider for Next 3 Upcoming EMI Payments
final next3UpcomingEmisProvider = FutureProvider.autoDispose((ref) async {
  // We need to re-fetch when the emi list changes
  ref.watch(emiListProvider);
  return ref.watch(_emiRepo).getUpcomingEmis(limit: 3);
});
