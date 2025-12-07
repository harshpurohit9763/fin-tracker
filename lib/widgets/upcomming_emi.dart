import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/models/emi_model.dart';

class UpcomingEmiPanel extends ConsumerWidget {
  const UpcomingEmiPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final upcomingEmisAsync = ref.watch(next3UpcomingEmisProvider);

    return upcomingEmisAsync.when(
      data: (emis) {
        if (emis.isEmpty) {
          return _SoftCard(
            padding: const EdgeInsets.all(20.0),
            child: Center(
                child: Text(
              'No upcoming EMIs. You\'re all set!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )),
          );
        }
        return _SoftCard(
          child: Column(
            children: List.generate(emis.length, (index) {
              final emi = emis[index];
              return _EmiListItem(
                emi: emi,
                currency: currency,
                isLast: index == emis.length - 1,
              );
            }),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _SoftCard(
        padding: const EdgeInsets.all(20.0),
        child: Center(
            child: Text(
          'Error loading EMIs: $err',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        )),
      ),
    );
  }
}

/// A reusable neomorphic card.
class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const _SoftCard({required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final lightShadow = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Color.lerp(backgroundColor, Colors.white, 0.7)!;
    final darkShadow = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            offset: const Offset(4, 4),
            blurRadius: 15,
          ),
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-4, -4),
            blurRadius: 15,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmiListItem extends StatelessWidget {
  final Emi emi;
  final String currency;
  final bool isLast;

  const _EmiListItem({
    required this.emi,
    required this.currency,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.credit_card,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emi.loanName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${AppFormatters.formatDate(emi.nextDueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.formatCurrency(emi.monthlyEmiAmount, currency),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
      ],
    );
  }
}
