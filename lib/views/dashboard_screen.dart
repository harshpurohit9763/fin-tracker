// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:personal_finance/views/financial_goals_screen.dart';
// import 'package:personal_finance/views/advanced_reports_screen.dart';
// import 'package:personal_finance/views/budgets_screen.dart';
// import 'package:personal_finance/controllers/expense_provider.dart';
// import 'package:personal_finance/views/insights_screen.dart';
// import 'package:personal_finance/views/net_worth_screen.dart';
// import 'package:personal_finance/helper/app_formater.dart';
// import 'package:personal_finance/controllers/dashboard_provider.dart';
// import 'package:personal_finance/controllers/emi_provider.dart';
// import 'package:personal_finance/widgets/matteric_card.dart';
// import 'package:personal_finance/widgets/monthly_trend.dart';
// import 'package:personal_finance/widgets/overlapping_card_view.dart';
// import 'package:personal_finance/widgets/flippable_emi_card.dart';
// import 'package:personal_finance/controllers/shared_preferences_provider.dart';
// import 'package:personal_finance/widgets/upcomming_emi.dart';
// import 'package:personal_finance/views/profile_screen.dart';
// import 'package:personal_finance/views/monthly_report_screen.dart';

// String _getGreeting() {
//   final hour = DateTime.now().hour;
//   if (hour < 12) {
//     return 'Good morning';
//   }
//   if (hour < 17) {
//     return 'Good afternoon';
//   }
//   return 'Good evening';
// }

// class DashboardScreen extends ConsumerStatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends ConsumerState<DashboardScreen> {
//   bool _showUpcomingEmis = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // _showTutorial(); // Removed tutorial call
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currency = ref.watch(currencyProvider);
//     final userName = ref.watch(userNameProvider);
//     // Watch providers for the metric cards
//     final monthSpendingAsync = ref.watch(currentMonthSpendingProvider);
//     final monthSavingsAsync = ref.watch(currentMonthSavingsProvider);
//     final upcomingEmisAsync = ref.watch(upcomingEmisThisWeekCountProvider);
//     final nextEmiAsync = ref.watch(next3UpcomingEmisProvider);

//     // Refresh dashboard when expense or EMI lists change
//     ref.watch(expenseListProvider);
//     ref.watch(emiListProvider);

//     return Scaffold(
//       body: RefreshIndicator(
//         onRefresh: () async {
//           // Invalidate all dashboard providers to refresh
//           ref.invalidate(currentMonthSpendingProvider);
//           ref.invalidate(upcomingEmisThisWeekCountProvider);
//           ref.invalidate(last6MonthsSpendingProvider);
//           ref.invalidate(next3UpcomingEmisProvider);
//         },
//         child: CustomScrollView(
//           slivers: [
//             nextEmiAsync.when(
//               data: (allEmis) {
//                 // Only show unpaid EMIs
//                 final now = DateTime.now();
//                 final endOfWeek = now.add(Duration(days: 7 - now.weekday));
//                 final emis = allEmis
//                     .where((e) =>
//                         e.tenureRemainingMonths > 0 &&
//                         e.nextDueDate.isBefore(endOfWeek))
//                     .toList();
//                 final hasEmi = emis.isNotEmpty;
//                 void navigateToProfile() {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const ProfileScreen()),
//                   );
//                 }

//                 return SliverAppBar(
//                   pinned: false,
//                   floating: true,
//                   snap: true,
//                   expandedHeight: hasEmi
//                       ? (1.sw - 48.w) / 1.586 + (emis.length * 10.h)
//                       : kToolbarHeight,
//                   flexibleSpace: FlexibleSpaceBar(
//                     titlePadding:
//                         EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                     centerTitle: false,
//                     title: hasEmi
//                         ? null // Hide title when EMI card is visible
//                         : FittedBox(
//                             fit: BoxFit.scaleDown,
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(_getGreeting(),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .labelLarge
//                                         ?.copyWith(fontSize: 12.sp)),
//                                 Text('$userName!',
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .titleMedium
//                                         ?.copyWith(fontSize: 16.sp)),
//                               ],
//                             ),
//                           ),
//                     background: hasEmi
//                         ? Padding(
//                             padding: EdgeInsets.only(
//                                 top: kToolbarHeight, left: 16.w, right: 16.w),
//                             child: OverlappingCardView(
//                               children: emis.map((emi) {
//                                 return FlippableEmiCard(
//                                   emi: emi,
//                                   currency: currency,
//                                   userName: userName,
//                                   onProfileTap: navigateToProfile,
//                                 );
//                               }).toList(),
//                             ),
//                           )
//                         : null,
//                   ),
//                   actions: hasEmi
//                       ? [] // No actions when EMI card is shown
//                       : [
//                           IconButton(
//                             icon: const CircleAvatar(child: Icon(Icons.person)),
//                             onPressed: navigateToProfile,
//                           ),
//                           SizedBox(width: 8.w),
//                         ],
//                 );
//               },
//               loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
//               error: (_, __) =>
//                   const SliverToBoxAdapter(child: SizedBox.shrink()),
//             ),
//             SliverPadding(
//               padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate(
//                   [
//                     // Key Metrics Cards
//                     Row(
//                       children: [
//                         Expanded(
//                           child: monthSpendingAsync.when(
//                             data: (total) => MetricCard(
//                               title: "Month's Spending",
//                               value: AppFormatters.formatCurrency(
//                                 total,
//                                 currency,
//                               ),
//                               icon: Icons.show_chart,
//                               color: Theme.of(context).colorScheme.primary,
//                               onIconTap: () {
//                                 debugPrint(
//                                     'This Month\'s Spending icon tapped!');
//                                 // Navigate to a detailed spending report or similar
//                               },
//                             ),
//                             loading: () => MetricCard(
//                                 title: "Month's Spending",
//                                 value: '...',
//                                 icon: Icons.show_chart,
//                                 color: Colors.grey,
//                                 onIconTap: () {
//                                   debugPrint(
//                                       'This Month\'s Spending icon tapped!');
//                                 }),
//                             error: (e, s) => MetricCard(
//                                 title: "Month's Spending",
//                                 value: 'Error',
//                                 icon: Icons.error,
//                                 color: Colors.redAccent,
//                                 onIconTap: () {
//                                   debugPrint(
//                                       'This Month\'s Spending icon tapped!');
//                                 }),
//                           ),
//                         ),
//                         SizedBox(width: 16.w),
//                         Expanded(
//                           child: monthSavingsAsync.when(
//                             data: (total) => MetricCard(
//                               title: "Month's Savings",
//                               value: AppFormatters.formatCurrency(
//                                 total,
//                                 currency,
//                               ),
//                               icon: Icons.savings_outlined,
//                               color: Colors.green,
//                               onIconTap: () {
//                                 Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (context) =>
//                                             const FinancialGoalsScreen()));
//                               },
//                             ),
//                             loading: () => MetricCard(
//                                 title: "Month's Savings",
//                                 value: '...',
//                                 icon: Icons.savings_outlined,
//                                 color: Colors.grey,
//                                 onIconTap: () {}),
//                             error: (e, s) => MetricCard(
//                                 title: "Month's Savings",
//                                 value: 'Error',
//                                 icon: Icons.error,
//                                 color: Colors.redAccent,
//                                 onIconTap: () {}),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 24.h),

//                     // EMI Due Panel
//                     if (_showUpcomingEmis) ...[
//                       Text('Upcoming EMI Payments',
//                           style: Theme.of(context)
//                               .textTheme
//                               .titleLarge
//                               ?.copyWith(fontSize: 20.sp)),
//                       SizedBox(height: 16.h),
//                       const UpcomingEmiPanel(),
//                       SizedBox(height: 24.h),
//                     ],

//                     // Monthly Trend Bar Chart
//                     const MonthlyTrendChart(),
//                     SizedBox(height: 24.h),

//                     // Financial Tools Grid
//                     Text('Financial Tools',
//                         style: Theme.of(context)
//                             .textTheme
//                             .titleLarge
//                             ?.copyWith(fontSize: 20.sp)),
//                     SizedBox(height: 16.h),
//                     GridView.count(
//                       crossAxisCount: 2,
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisSpacing: 16.w,
//                       mainAxisSpacing: 16.h,
//                       childAspectRatio: 1.2,
//                       children: [
//                         _FeatureTile(
//                             title: 'Monthly Report',
//                             icon: Icons.calendar_month_outlined,
//                             color: Colors.red,
//                             onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         const MonthlyReportScreen()))),
//                         _FeatureTile(
//                             title: 'Budgets',
//                             icon: Icons.track_changes_outlined,
//                             color: Colors.orange,
//                             onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         const BudgetsScreen()))),
//                         _FeatureTile(
//                             title: 'Insights',
//                             icon: Icons.lightbulb_outline,
//                             color: Colors.blue,
//                             onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         const InsightsScreen()))),
//                         _FeatureTile(
//                             title: 'Net Worth',
//                             icon: Icons.assessment_outlined,
//                             color: Colors.green,
//                             onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         const NetWorthScreen()))),
//                         _FeatureTile(
//                             title: 'Advance Reports',
//                             icon: Icons.analytics_outlined,
//                             color: Colors.purple,
//                             onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         const AdvancedReportsScreen()))),
//                         _FeatureTile(
//                             title: 'Financial Goals',
//                             icon: Icons.flag_outlined,
//                             color: Colors.cyan,
//                             onTap: () {
//                               Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                       builder: (context) =>
//                                           const FinancialGoalsScreen()));
//                             }),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// A tappable card for navigating to a feature screen.
// class _FeatureTile extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final VoidCallback onTap;
//   final Color color; // This color will be used for the icon background

//   const _FeatureTile({
//     required this.title,
//     required this.icon,
//     required this.onTap,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
//     final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
//     final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(24.r),
//           boxShadow: [
//             BoxShadow(
//               color: darkShadow,
//               blurRadius: 10.r,
//               offset: Offset(5.w, 5.h),
//             ),
//             BoxShadow(
//               color: lightShadow,
//               blurRadius: 10.r,
//               offset: Offset(-5.w, -5.h),
//             ),
//           ],
//         ),
//         padding: EdgeInsets.all(12.w),
//         child: SingleChildScrollView(
//           physics: const NeverScrollableScrollPhysics(),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 56.w,
//                 height: 56.h,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: color, // Use the provided color for the background
//                 ),
//                 child: Icon(icon,
//                     size: 28.sp, color: Colors.white), // Icon color is white
//               ),
//               SizedBox(height: 12.h),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14.sp,
//                       color: Theme.of(context).colorScheme.onSurface,
//                     ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:personal_finance/views/financial_goals_screen.dart';
import 'package:personal_finance/views/advanced_reports_screen.dart';
import 'package:personal_finance/views/budgets_screen.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/views/insights_screen.dart';
import 'package:personal_finance/views/net_worth_screen.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/widgets/matteric_card.dart';
import 'package:personal_finance/widgets/monthly_trend.dart';
import 'package:personal_finance/widgets/overlapping_card_view.dart';
import 'package:personal_finance/widgets/flippable_emi_card.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/widgets/upcomming_emi.dart';
import 'package:personal_finance/views/profile_screen.dart';
import 'package:personal_finance/views/monthly_report_screen.dart';

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final bool _showUpcomingEmis = false; // Toggle if needed

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final userName = ref.watch(userNameProvider);
    final monthSpendingAsync = ref.watch(currentMonthSpendingProvider);
    final monthSavingsAsync = ref.watch(currentMonthSavingsProvider);
    final nextEmiAsync = ref.watch(next3UpcomingEmisProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Refresh lists
    ref.watch(expenseListProvider);
    ref.watch(emiListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentMonthSpendingProvider);
          ref.invalidate(upcomingEmisThisWeekCountProvider);
          ref.invalidate(last6MonthsSpendingProvider);
          ref.invalidate(next3UpcomingEmisProvider);
        },
        child: CustomScrollView(
          slivers: [
            // --- 1. Sliver App Bar with Dynamic EMI Header ---
            nextEmiAsync.when(
              data: (allEmis) {
                // Filter active EMIs due this week
                final now = DateTime.now();
                final endOfWeek = now.add(Duration(days: 7 - now.weekday));
                final activeEmis = allEmis
                    .where((e) =>
                        e.tenureRemainingMonths > 0 &&
                        e.nextDueDate.isBefore(endOfWeek))
                    .toList();

                final hasEmi = activeEmis.isNotEmpty;

                return SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight:
                      hasEmi ? 280 : 120, // Taller if displaying EMI card
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: hasEmi
                        ? Padding(
                            padding: const EdgeInsets.only(top: 80, bottom: 20),
                            child: OverlappingCardView(
                              children: activeEmis
                                  .map((emi) => FlippableEmiCard(
                                        emi: emi,
                                        currency: currency,
                                        userName: userName,
                                        onProfileTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ProfileScreen())),
                                      ))
                                  .toList(),
                            ),
                          )
                        : null,
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: hasEmi
                        ? null
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    userName.isEmpty ? 'User' : userName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              // Profile Icon
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ProfileScreen())),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    child: Icon(Icons.person,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                  ),
                                ),
                              )
                            ],
                          ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // --- 2. Dashboard Content ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),

                  // A. Metrics Row (Spending & Savings)
                  Row(
                    children: [
                      Expanded(
                        child: monthSpendingAsync.when(
                          data: (val) => _buildGradientMetricCard(
                            context,
                            title: "Spending",
                            amount: val,
                            currency: currency,
                            icon: Icons.trending_down,
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF8A65),
                                  Color(0xFFFF5252)
                                ], // Orange to Red
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                          ),
                          loading: () => const SizedBox(
                              height: 100,
                              child:
                                  Center(child: CircularProgressIndicator())),
                          error: (_, __) => const Text("Error"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: monthSavingsAsync.when(
                          data: (val) => _buildGradientMetricCard(
                            context,
                            title: "Savings",
                            amount: val,
                            currency: currency,
                            icon: Icons.savings_outlined,
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF66BB6A),
                                  Color(0xFF43A047)
                                ], // Light to Dark Green
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                          ),
                          loading: () => const SizedBox(height: 100),
                          error: (_, __) => const Text("Error"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // B. Upcoming EMI List (if enabled/available)
                  if (_showUpcomingEmis) ...[
                    Text("Upcoming Payments",
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const UpcomingEmiPanel(),
                    const SizedBox(height: 24),
                  ],

                  // C. Monthly Trend Chart
                  const MonthlyTrendChart(),

                  const SizedBox(height: 32),

                  // D. Tools Grid Header
                  Text("Financial Tools",
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),

                  // E. Tools Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _FeatureTile(
                        title: 'Reports',
                        icon: Icons.pie_chart_rounded,
                        color: Colors.purpleAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MonthlyReportScreen())),
                      ),
                      _FeatureTile(
                        title: 'Budgets',
                        icon: Icons.track_changes_rounded,
                        color: Colors.orangeAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BudgetsScreen())),
                      ),
                      _FeatureTile(
                        title: 'Insights',
                        icon: Icons.lightbulb_rounded,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InsightsScreen())),
                      ),
                      _FeatureTile(
                        title: 'Net Worth',
                        icon: Icons.account_balance_rounded,
                        color: Colors.tealAccent.shade700,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NetWorthScreen())),
                      ),
                      _FeatureTile(
                        title: 'Advanced',
                        icon: Icons.analytics_rounded,
                        color: Colors.indigoAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdvancedReportsScreen())),
                      ),
                      _FeatureTile(
                        title: 'Goals',
                        icon: Icons.flag_rounded,
                        color: Colors.pinkAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FinancialGoalsScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Gradient Metric Card ---
  Widget _buildGradientMetricCard(
    BuildContext context, {
    required String title,
    required double amount,
    required String currency,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              // Optional: Add small trend arrow here
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.formatCurrency(amount, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- Helper: Feature Tile (Soft UI) ---
class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _FeatureTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
