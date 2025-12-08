import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class IncomeCard extends ConsumerWidget {
  final Income income;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkAsReceived;
  final bool showMarkAsReceived;

  const IncomeCard({
    super.key,
    required this.income,
    this.onEdit,
    this.onDelete,
    this.onMarkAsReceived,
    this.showMarkAsReceived = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Dynamic Accent Color (Source of Truth)
    final accentColor = colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        // Soft background color based on theme
        color: isDark
            ? const Color(0xFF1E1E1E) // Dark graphite for Dark Mode
            : Colors.white, // Clean white for Light Mode
        borderRadius: BorderRadius.circular(24),
        // Subtle Border
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        // Soft Shadow for Depth
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit, // Make the whole card clickable for edit if desired
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- Top Row: Icon + Info + Amount ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Category/Income Icon
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons
                            .arrow_downward_rounded, // or use specific category icons
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 2. Title & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            income.description,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatDate(income.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Amount & Recurring Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "+${AppFormatters.formatCurrency(income.amount, currency)}",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.greenAccent[
                                700], // Keep income green or use accent
                            fontSize: 18,
                          ),
                        ),
                        if (income.isMonthly) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Recurring',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // --- Bottom Actions Section ---
                if (onEdit != null ||
                    onDelete != null ||
                    (showMarkAsReceived && onMarkAsReceived != null)) ...[
                  const SizedBox(height: 20),
                  // Divider Line
                  Container(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Source Label
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.wallet,
                                size: 14, color: theme.hintColor),
                            const SizedBox(width: 6),
                            Text(
                              income.source,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Row(
                        children: [
                          if (showMarkAsReceived && onMarkAsReceived != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: onMarkAsReceived,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Receive",
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (onEdit != null)
                            _buildMiniActionButton(
                              context,
                              icon: Icons.edit_rounded,
                              onTap: onEdit,
                              tooltip: 'Edit',
                            ),
                          const SizedBox(width: 8),
                          if (onDelete != null)
                            _buildMiniActionButton(
                              context,
                              icon: Icons.delete_outline_rounded,
                              onTap: onDelete,
                              color: colorScheme.error,
                              tooltip: 'Delete',
                            ),
                        ],
                      )
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for small circular action buttons
  Widget _buildMiniActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    Color? color,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (color ?? theme.iconTheme.color)?.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? theme.iconTheme.color?.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
