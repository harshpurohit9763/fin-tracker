import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/emi_provider.dart';
import 'package:personal_finance/emi_repo.dart';
import 'package:personal_finance/report_repo.dart';

// Provides the repository instances
final _reportRepo = Provider((ref) => ReportRepository());
final _emiRepo = Provider((ref) => EmiRepository());

// Provider for Current Month's Total Spending
final currentMonthSpendingProvider = FutureProvider<double>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  return ref.watch(_reportRepo).getTotalForDateRange(startOfMonth, endOfMonth);
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
