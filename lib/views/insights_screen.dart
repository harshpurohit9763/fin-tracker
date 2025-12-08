import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/widgets/cash_flow_chart.dart';
import 'manage_subscriptions_screen.dart';
import '../controllers/subscription_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background color slightly off-white for contrast against white cards
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // --- Modern App Bar ---
          SliverAppBar(
            backgroundColor: bgColor,
            expandedHeight: 80.0,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.white10 : Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: theme.iconTheme.color,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            centerTitle: true,
            title: Text(
              'Insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),

          // --- Content ---
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _NeedsVsWantsSection(),
                SizedBox(height: 32),
                _SubscriptionTrackerSection(),
                SizedBox(height: 32),
                _CashFlowSection(),
                SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 1. Needs vs Wants Section (Donut Chart) ---
class _NeedsVsWantsSection extends ConsumerWidget {
  const _NeedsVsWantsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(spendingBreakdownProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return breakdownAsync.when(
      data: (data) {
        if (data.total == 0) return const SizedBox(); // Or empty state

        return Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Where your money goes",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("This Month",
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Chart Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]),
              child: Column(
                children: [
                  // The Donut Chart
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4, // Spacing between sections
                            centerSpaceRadius: 60, // Large hole for Donut
                            sections: [
                              _buildSection(data.needs, const Color(0xFF6C63FF),
                                  data.total), // Purple
                              _buildSection(data.wants, const Color(0xFFFF6584),
                                  data.total), // Pink
                              _buildSection(data.investments,
                                  const Color(0xFF4DB6AC), data.total), // Teal
                            ],
                          ),
                        ),
                        // Center Text
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Total",
                                  style: TextStyle(
                                      color: theme.hintColor, fontSize: 12)),
                              Text(
                                AppFormatters.formatCurrency(
                                    data.total, currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Custom Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _LegendPill(
                          color: const Color(0xFF6C63FF),
                          label: "Needs",
                          amount: data.needs,
                          currency: currency),
                      _LegendPill(
                          color: const Color(0xFFFF6584),
                          label: "Wants",
                          amount: data.wants,
                          currency: currency),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LegendPill(
                      color: const Color(0xFF4DB6AC),
                      label: "Savings",
                      amount: data.investments,
                      currency: currency),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  PieChartSectionData _buildSection(double value, Color color, double total) {
    final isLarge = value / total > 0.5;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '', // Hide title on chart
      radius: isLarge ? 25 : 20, // Make larger section pop slightly
      showTitle: false,
      badgeWidget: null,
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  final String currency;

  const _LegendPill(
      {required this.color,
      required this.label,
      required this.amount,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(AppFormatters.formatCurrency(amount, currency),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// --- 2. Subscriptions Section (Horizontal Cards) ---
class _SubscriptionTrackerSection extends ConsumerWidget {
  const _SubscriptionTrackerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionListProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recurring Bills",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageSubscriptionsScreen())),
              child: Text("See All",
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        subscriptionsAsync.when(
          data: (subs) {
            if (subs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("No active subscriptions",
                    textAlign: TextAlign.center),
              );
            }

            // Horizontal ScrollView for Cards
            return SizedBox(
              height: 140, // Height of the card
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: subs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  // Alternating Colors for visual interest
                  final isEven = index % 2 == 0;
                  final cardColor =
                      isEven ? const Color(0xFF2D2D2D) : Colors.white;
                  final textColor = isEven ? Colors.white : Colors.black;

                  return Container(
                    width: 130,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5))
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white24 : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt,
                              color: isEven ? Colors.white : Colors.black,
                              size: 18),
                        ),
                        // Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatCurrency(
                                  sub.amount, currency),
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        )
      ],
    );
  }
}

// --- 3. Cash Flow Section (Clean Line Chart) ---
class _CashFlowSection extends ConsumerWidget {
  const _CashFlowSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowDataProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Cash Flow Trends",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]),
          child: Column(
            children: [
              cashFlowAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: Text("Not enough data")),
                    );
                  }
                  return SizedBox(
                    height: 200,
                    // Pass specific styling to your chart widget if it supports it
                    // Or ensure CashFlowChart uses Theme colors
                    child: CashFlowChart(cashFlowData: data),
                  );
                },
                loading: () => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(height: 150),
              ),
              const SizedBox(height: 16),
              // Clean Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SimpleLegend(color: Colors.green, label: "In"),
                  const SizedBox(width: 16),
                  _SimpleLegend(color: Colors.redAccent, label: "Out"),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _SimpleLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
