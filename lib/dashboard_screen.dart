import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/add_expense.dart';
import 'package:personal_finance/advanced_reports_screen.dart';
import 'package:personal_finance/budgets_screen.dart';
import 'package:personal_finance/insights_screen.dart';
import 'package:personal_finance/net_worth_screen.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/category_provider.dart';
import 'package:personal_finance/dashboard_provider.dart';
import 'package:personal_finance/emi_provider.dart';
import 'package:personal_finance/matteric_card.dart';
import 'package:personal_finance/monthly_trend.dart';
import 'package:personal_finance/overlapping_card_view.dart';
import 'package:personal_finance/flippable_emi_card.dart';
import 'package:personal_finance/shared_preferences_provider.dart';
import 'package:personal_finance/tutorial_overlay.dart';
import 'package:personal_finance/upcomming_emi.dart';
import 'package:personal_finance/upcoming_emi_card.dart';
import 'package:personal_finance/profile_screen.dart';

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
  // Keys for tutorial
  final GlobalKey _profileButtonKey = GlobalKey();
  final GlobalKey _metricsCardKey = GlobalKey();
  final GlobalKey _monthlyTrendKey = GlobalKey();
  final GlobalKey _toolsGridKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  Future<void> _showTutorial() async {
    final tutorialProvider = ref.read(tutorialVisibilityProvider);
    final isSeen = await tutorialProvider.isTutorialSeen('dashboard');
    if (!isSeen && mounted) {
      final steps = [
        TutorialStep(
          key: _profileButtonKey,
          text:
              'Welcome! Tap here to manage your profile, settings, and categories.',
          shape: const CircleBorder(),
        ),
        TutorialStep(
          key: _metricsCardKey,
          text:
              'These cards show a quick summary of your spending and upcoming EMIs for the current period.',
        ),
        TutorialStep(
          key: _monthlyTrendKey,
          text:
              'This chart visualizes your spending habits over the last 6 months.',
        ),
        TutorialStep(
          key: _toolsGridKey,
          text:
              'Explore powerful tools like Budgets, Insights, and Net Worth tracking here.',
        ),
        TutorialStep(
          key: _fabKey,
          text: 'Tap this button anytime to quickly add a new expense.',
          shape: const CircleBorder(),
        ),
      ];

      await TutorialOverlay.show(context, steps, () {
        tutorialProvider.setTutorialSeen('dashboard');
      });
    }
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
                          (emis.length * 40)
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
                            key: _profileButtonKey,
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
                delegate: SliverChildListDelegate([
                  // Key Metrics Cards
                  KeyedSubtree(
                    key: _metricsCardKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: totalSpendingAsync.when(
                                  data: (total) => MetricCard(
                                    title: "This Month's Spending",
                                    value: AppFormatters.formatCurrency(
                                      total,
                                      currency,
                                    ),
                                    icon: Icons.show_chart,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  loading: () => const MetricCard(
                                      title: "This Month's Spending",
                                      value: '...',
                                      icon: Icons.show_chart,
                                      color: Colors.grey),
                                  error: (e, s) => const MetricCard(
                                      title: "This Month's Spending",
                                      value: 'Error',
                                      icon: Icons.error,
                                      color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: upcomingEmisAsync.when(
                                  data: (count) => MetricCard(
                                    title: 'EMIs Due This Week',
                                    value: '$count Payments',
                                    icon: Icons.payment,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                  loading: () => const MetricCard(
                                      title: 'EMIs Due This Week',
                                      value: '...',
                                      icon: Icons.payment,
                                      color: Colors.grey),
                                  error: (e, s) => const MetricCard(
                                      title: 'EMIs Due This Week',
                                      value: 'Error',
                                      icon: Icons.error,
                                      color: Colors.redAccent),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              totalSpendingAsync.when(
                                data: (total) => MetricCard(
                                  title: "This Month's Spending",
                                  value: AppFormatters.formatCurrency(
                                      total, currency),
                                  icon: Icons.show_chart,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                loading: () => const MetricCard(
                                    title: "This Month's Spending",
                                    value: '...',
                                    icon: Icons.show_chart,
                                    color: Colors.grey),
                                error: (e, s) => const MetricCard(
                                    title: "This Month's Spending",
                                    value: 'Error',
                                    icon: Icons.error,
                                    color: Colors.redAccent),
                              ),
                              const SizedBox(height: 16),
                              upcomingEmisAsync.when(
                                data: (count) => MetricCard(
                                  title: 'EMIs Due This Week',
                                  value: '$count Payments',
                                  icon: Icons.payment,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                loading: () => const MetricCard(
                                    title: 'EMIs Due This Week',
                                    value: '...',
                                    icon: Icons.payment,
                                    color: Colors.grey),
                                error: (e, s) => const MetricCard(
                                    title: 'EMIs Due This Week',
                                    value: 'Error',
                                    icon: Icons.error,
                                    color: Colors.redAccent),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monthly Trend Bar Chart
                  Text('Monthly Spending Trend (Last 6 Months)',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: _monthlyTrendKey,
                    child:
                        const SizedBox(height: 250, child: MonthlyTrendChart()),
                  ),
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
                  KeyedSubtree(
                    key: _toolsGridKey,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
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
                            title: 'Reports',
                            icon: Icons.analytics_outlined,
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AdvancedReportsScreen()))),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
