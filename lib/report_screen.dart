// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:personal_finance/app_formater.dart';
// import 'package:personal_finance/category_pie_chart.dart';
// import 'package:personal_finance/report_provider.dart';
// import 'package:personal_finance/shared_preferences_provider.dart';

// class ReportingScreen extends ConsumerWidget {
//   const ReportingScreen({super.key});

//   Future<void> _selectCustomDateRange(
//       BuildContext context, WidgetRef ref) async {
//     final initialRange = ref.read(currentDateRangeProvider);
//     final picked = await showDateRangePicker(
//       context: context,
//       initialDateRange: initialRange,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null) {
//       ref.read(customDateRangeProvider.notifier).state = picked;
//       ref.read(reportDateRangeTypeProvider.notifier).state =
//           ReportDateRangeType.custom;
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final totalAsync = ref.watch(selectedRangeTotalProvider);
//     final rangeType = ref.watch(reportDateRangeTypeProvider);
//     final currency = ref.watch(currencyProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reports'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Date Range Selector
//             DropdownButtonFormField<ReportDateRangeType>(
//               value: rangeType,
//               onChanged: (newValue) {
//                 if (newValue == ReportDateRangeType.custom) {
//                   _selectCustomDateRange(context, ref);
//                 } else {
//                   ref.read(reportDateRangeTypeProvider.notifier).state =
//                       newValue!;
//                 }
//               },
//               items: const [
//                 DropdownMenuItem(
//                     value: ReportDateRangeType.thisMonth,
//                     child: Text('This Month')),
//                 DropdownMenuItem(
//                     value: ReportDateRangeType.last7Days,
//                     child: Text('Last 7 Days')),
//                 DropdownMenuItem(
//                     value: ReportDateRangeType.last30Days,
//                     child: Text('Last 30 Days')),
//                 DropdownMenuItem(
//                     value: ReportDateRangeType.custom,
//                     child: Text('Custom Range...')),
//                 DropdownMenuItem(
//                     value: ReportDateRangeType.monthly,
//                     child: Text('Monthly Breakdown')),
//               ],
//               decoration: const InputDecoration(
//                 labelText: 'Report Period',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Monthly Breakdown
//             if (rangeType == ReportDateRangeType.monthly)
//               _buildMonthlyBreakdown(ref, currency)
//             else ...[
//               // Total Card
//               Card(
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Total Spending',
//                         style: Theme.of(context).textTheme.titleMedium,
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 12),
//                       totalAsync.when(
//                         data: (total) => Text(
//                           AppFormatters.formatCurrency(total, currency),
//                           style: Theme.of(context)
//                               .textTheme
//                               .headlineLarge
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color:
//                                     Theme.of(context).colorScheme.primary,
//                               ),
//                         ),
//                         loading: () => const CircularProgressIndicator(),
//                         error: (err, s) => Text('Error: $err'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Category Breakdown Pie Chart
//               Text(
//                 'Category Breakdown',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               const SizedBox(height: 16),
//               const SizedBox(height: 300, child: CategoryPieChartWidget()),
//               const SizedBox(height: 24),

//               // Daily Spending Trend Line Chart
//               Text(
//                 'Daily Spending Trend',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               const SizedBox(height: 16),
//               const SizedBox(height: 300, child: DailyTrendChartWidget()),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMonthlyBreakdown(WidgetRef ref, String currency) {
//     final monthlyAsync = ref.watch(monthlyBreakdownProvider);

//     return monthlyAsync.when(
//       data: (monthlyData) {
//         if (monthlyData.isEmpty) {
//           return const Center(child: Text('No spending data for this period.'));
//         }
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Monthly Spending Breakdown',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 16),
//             ...monthlyData.entries.map((entry) {
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         entry.key, // Month-Year
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       Text(
//                         AppFormatters.formatCurrency(entry.value, currency),
//                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: Theme.of(context).colorScheme.secondary,
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ],
//         );
//       },
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (err, s) => Center(child: Text('Error: $err')),
//     );
//   }
// }

// // A new widget for the daily trend chart
// class DailyTrendChartWidget extends ConsumerWidget {
//   const DailyTrendChartWidget({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final trendAsync = ref.watch(dailyTrendProvider);
//     return trendAsync.when(
//       data: (data) {
//         if (data.isEmpty) {
//           return const Center(child: Text('No spending in this period.'));
//         }
//         // This is a placeholder for a real chart implementation
//         return Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Center(
//             child: Text(
//               'Daily Trend Chart will be here',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ),
//         );
//       },
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (err, stack) => Center(child: Text('Error: $err')),
//     );
//   }
// }
