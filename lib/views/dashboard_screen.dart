import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:personal_finance/views/financial_goals_screen.dart';
import 'package:personal_finance/views/advanced_reports_screen.dart';
import 'package:personal_finance/views/budgets_screen.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/views/insights_screen.dart';
import 'package:personal_finance/views/net_worth_screen.dart';
import 'package:personal_finance/helper/themes.dart';
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
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showUpcomingEmis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showTutorial(); // Removed tutorial call
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final userName = ref.watch(userNameProvider);
    // Watch providers for the metric cards
    final monthSpendingAsync = ref.watch(currentMonthSpendingProvider);
    final monthSavingsAsync = ref.watch(currentMonthSavingsProvider);
    final upcomingEmisAsync = ref.watch(upcomingEmisThisWeekCountProvider);
    final nextEmiAsync = ref.watch(next3UpcomingEmisProvider);

    // Refresh dashboard when expense or EMI lists change
    ref.watch(expenseListProvider);
    ref.watch(emiListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all dashboard providers to refresh
          ref.invalidate(currentMonthSpendingProvider);
          ref.invalidate(upcomingEmisThisWeekCountProvider);
          ref.invalidate(last6MonthsSpendingProvider);
          ref.invalidate(next3UpcomingEmisProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: monthSpendingAsync.when(
                  data: (total) {
                    final themeHelper =
                        ThemeHelper(Theme.of(context).colorScheme.primary);
                    return _ProminentMetricCard(
                      title: "Month's Spending",
                      value: AppFormatters.formatCurrency(total, currency),
                      icon: Icons.show_chart,
                      gradient: themeHelper.primaryGradient,
                    );
                  },
                  loading: () => _ProminentMetricCard(
                    title: "Month's Spending",
                    value: '...',
                    icon: Icons.show_chart,
                    gradient: LinearGradient(
                        colors: [Colors.grey, Colors.grey.shade600]),
                  ),
                  error: (e, s) => _ProminentMetricCard(
                    title: "Month's Spending",
                    value: 'Error',
                    icon: Icons.error,
                    gradient: LinearGradient(
                        colors: [Colors.red, Colors.red.shade800]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            nextEmiAsync.when(
              data: (allEmis) {
                final now = DateTime.now();
                final endOfWeek = now.add(Duration(days: 7 - now.weekday));
                final emis = allEmis
                    .where((e) =>
                        e.tenureRemainingMonths > 0 &&
                        e.nextDueDate.isBefore(endOfWeek))
                    .toList();
                if (emis.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    // The PageView inside OverlappingCardView needs a constrained height.
                    child: SizedBox(
                      // Calculate height based on card aspect ratio (1.586) and overlap.
                      height:
                          (1.sw - 32.w) / 1.586 + ((emis.length - 1) * 20.h),
                      child: OverlappingCardView(
                        children: emis.map((emi) {
                          return FlippableEmiCard(
                            emi: emi,
                            currency: currency,
                            userName: userName,
                            onProfileTap: () {},
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                sliver: SliverList(
                    delegate: SliverChildListDelegate(
                  [
                    // Other metric cards
                    monthSavingsAsync.when(
                      data: (total) => _MetricSummaryCard(
                        title: "Month's Savings",
                        value: AppFormatters.formatCurrency(total, currency),
                        icon: Icons.savings_outlined,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const FinancialGoalsScreen()));
                        },
                      ),
                      loading: () => _MetricSummaryCard(
                          title: "Month's Savings",
                          value: '...',
                          icon: Icons.savings_outlined,
                          color: Colors.grey,
                          onTap: () {}),
                      error: (e, s) => _MetricSummaryCard(
                          title: "Month's Savings",
                          value: 'Error',
                          icon: Icons.error,
                          color: Colors.redAccent,
                          onTap: () {}),
                    ),
                    SizedBox(height: 24.h),
                    // The old layout had two cards in a row. Now they are stacked.
                    /*
                    Row(
                      children: [
                        Expanded(
                          child: monthSpendingAsync.when(
                            data: (total) => MetricCard(
                              title: "Month's Spending",
                              value: AppFormatters.formatCurrency(
                                total,
                                currency,
                              ),
                              icon: Icons.show_chart,
                              color: Theme.of(context).colorScheme.primary,
                              onIconTap: () {
                                debugPrint(
                                    'This Month\'s Spending icon tapped!');
                                // Navigate to a detailed spending report or similar
                              },
                            ),
                            loading: () => MetricCard(
                                title: "Month's Spending",
                                value: '...',
                                icon: Icons.show_chart,
                                color: Colors.grey,
                                onIconTap: () {
                                  debugPrint(
                                      'This Month\'s Spending icon tapped!');
                                }),
                            error: (e, s) => MetricCard(
                                title: "Month's Spending",
                                value: 'Error',
                                icon: Icons.error,
                                color: Colors.redAccent,
                                onIconTap: () {
                                  debugPrint(
                                      'This Month\'s Spending icon tapped!');
                                }),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: monthSavingsAsync.when(
                            data: (total) => MetricCard(
                              title: "Month's Savings",
                              value: AppFormatters.formatCurrency(
                                total,
                                currency,
                              ),
                              icon: Icons.savings_outlined,
                              color: Colors.green,
                              onIconTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const FinancialGoalsScreen()));
                              },
                            ),
                            loading: () => MetricCard(
                                title: "Month's Savings",
                                value: '...',
                                icon: Icons.savings_outlined,
                                color: Colors.grey,
                                onIconTap: () {}),
                            error: (e, s) => MetricCard(
                                title: "Month's Savings",
                                value: 'Error',
                                icon: Icons.error,
                                color: Colors.redAccent,
                                onIconTap: () {}),
                          ),
                        ),
                        
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // EMI Due Panel
                    if (_showUpcomingEmis) ...[
                      Text('Upcoming EMI Payments',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 20.sp)),
                      SizedBox(height: 16.h),
                      const UpcomingEmiPanel(),
                      SizedBox(height: 24.h),
                      */

                    // Monthly Trend Bar Chart
                    const MonthlyTrendChart(),
                    SizedBox(height: 24.h),

                    // Financial Tools Grid
                    Text('Financial Tools',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 20.sp)),
                    SizedBox(height: 16.h),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 1.2,
                      children: [
                        _FeatureTile(
                            title: 'Monthly Report',
                            icon: Icons.calendar_month_outlined,
                            color: Colors.red,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const MonthlyReportScreen()))),
                        _FeatureTile(
                            title: 'Budgets',
                            icon: Icons.track_changes_outlined,
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const BudgetsScreen()))),
                        _FeatureTile(
                            title: 'Insights',
                            icon: Icons.lightbulb_outline,
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const InsightsScreen()))),
                        _FeatureTile(
                            title: 'Net Worth',
                            icon: Icons.assessment_outlined,
                            color: Colors.green,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NetWorthScreen()))),
                        _FeatureTile(
                            title: 'Advance Reports',
                            icon: Icons.analytics_outlined,
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AdvancedReportsScreen()))),
                        _FeatureTile(
                            title: 'Financial Goals',
                            icon: Icons.flag_outlined,
                            color: Colors.cyan,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const FinancialGoalsScreen()));
                            }),
                      ],
                    ),
                  ],
                )))
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);

    void navigateToProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16.w, 16.h + MediaQuery.of(context).padding.top, 16.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '$userName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          GestureDetector(
            onTap: navigateToProfile,
            child: CircleAvatar(
              radius: 24.r,
              child: const Icon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable card for navigating to a feature screen.
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.4)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.15)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: darkShadow,
              offset: const Offset(5, 5),
              blurRadius: 15,
            ),
            BoxShadow(
              color: lightShadow,
              offset: const Offset(-5, -5),
              blurRadius: 15,
            ),
          ],
        ),
        padding: EdgeInsets.all(12.w),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Icon(icon, size: 28.sp, color: Colors.white),
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neomorphic styled card for secondary metrics.
class _MetricSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.4)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.15)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
                color: darkShadow, offset: const Offset(4, 4), blurRadius: 15),
            BoxShadow(
                color: lightShadow,
                offset: const Offset(-4, -4),
                blurRadius: 15),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Icon(icon, color: color, size: 24.sp),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// A prominent card with a gradient background.
class _ProminentMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _ProminentMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white)),
          SizedBox(height: 8.h),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
