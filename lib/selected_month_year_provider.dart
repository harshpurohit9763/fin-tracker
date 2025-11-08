import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedMonthYearProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
