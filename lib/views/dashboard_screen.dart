import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/widgets/add_expense.dart';
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
  bool _showFabOptions = false;

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
    final totalSpendingAsync = ref.watch(currentMonthSpendingProvider);
    final upcomingEmisAsync = ref.watch(upcomingEmisThisWeekCountProvider);
    final nextEmiAsync = ref.watch(next3UpcomingEmisProvider);

    // Refresh dashboard when expense or EMI lists change
    ref.watch(expenseListProvider);
    ref.watch(emiListProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // We will build our own app bar in the body
        elevation: 0,
      ),
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
            nextEmiAsync.when(
              data: (allEmis) {
                // Only show unpaid EMIs
                final now = DateTime.now();
                final endOfWeek = now.add(Duration(days: 7 - now.weekday));
                final emis = allEmis
                    .where((e) =>
                        e.tenureRemainingMonths > 0 &&
                        e.nextDueDate.isBefore(endOfWeek))
                    .toList();
                final hasEmi = emis.isNotEmpty;
                void navigateToProfile() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                }

                return SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: hasEmi
                      ?
                      // Calculate height: card height + overlap for other cards
                      (MediaQuery.of(context).size.width - 48) / 1.586 +
                          (emis.length * 10)
                      : kToolbarHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    centerTitle: false,
                    title: hasEmi
                        ? null // Hide title when EMI card is visible
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getGreeting(),
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                Text('$userName!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                          ),
                    background: hasEmi
                        ? OverlappingCardView(
                            children: emis.map((emi) {
                              return FlippableEmiCard(
                                emi: emi,
                                currency: currency,
                                userName: userName,
                                onProfileTap: navigateToProfile,
                              );
                            }).toList(),
                          )
                        : null,
                  ),
                  actions: hasEmi
                      ? [] // No actions when EMI card is shown
                      : [
                          IconButton(
                            icon: const CircleAvatar(child: Icon(Icons.person)),
                            onPressed: navigateToProfile,
                          ),
                          const SizedBox(width: 8),
                        ],
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // Key Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: totalSpendingAsync.when(
                            data: (total) => MetricCard(
                              title: "Month's Spending",
                              value: AppFormatters.formatCurrency(
                                total,
                                currency,
                              ),
                              icon: Icons.show_chart,
                              color: Theme.of(context).colorScheme.primary,
                              onIconTap: () {
                                debugPrint('This Month\'s Spending icon tapped!');
                                // Navigate to a detailed spending report or similar
                              },
                            ),
                            loading: () => MetricCard(
                                title: "Month's Spending",
                                value: '...',
                                icon: Icons.show_chart,
                                color: Colors.grey,
                                onIconTap: () {
                                  debugPrint('This Month\'s Spending icon tapped!');
                                }),
                            error: (e, s) => MetricCard(
                                title: "Month's Spending",
                                value: 'Error',
                                icon: Icons.error,
                                color: Colors.redAccent,
                                onIconTap: () {
                                  debugPrint('This Month\'s Spending icon tapped!');
                                }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: upcomingEmisAsync.when(
                            data: (count) => MetricCard(
                              title: 'EMIs Due This Week',
                              value: '$count Payments',
                              icon: Icons.payment,
                              color: Theme.of(context).colorScheme.secondary,
                              onIconTap: () {
                                debugPrint('EMIs Due This Week icon tapped!');
                                // Navigate to the EMI list screen or similar
                              },
                            ),
                            loading: () => MetricCard(
                                title: 'EMIs Due This Week',
                                value: '...',
                                icon: Icons.payment,
                                color: Colors.grey,
                                onIconTap: () {
                                  debugPrint('EMIs Due This Week icon tapped!');
                                }),
                            error: (e, s) => MetricCard(
                                title: 'EMIs Due This Week',
                                value: 'Error',
                                icon: Icons.error,
                                color: Colors.redAccent,
                                onIconTap: () {
                                  debugPrint('EMIs Due This Week icon tapped!');
                                }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Monthly Trend Bar Chart
                    const MonthlyTrendChart(),
                    const SizedBox(height: 24),

                    // EMI Due Panel
                    Text('Upcoming EMI Payments',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    const UpcomingEmiPanel(),
                    const SizedBox(height: 24),

                    // Financial Tools Grid
                    Text('Financial Tools',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

/// A tappable card for navigating to a feature screen.
class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color; // This color will be used for the icon background

  const _FeatureTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color, // Use the provided color for the background
              ),
              child: Icon(icon, size: 28, color: Colors.white), // Icon color is white
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
