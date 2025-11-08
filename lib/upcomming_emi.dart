import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/dashboard_provider.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

class UpcomingEmiPanel extends ConsumerWidget {
  const UpcomingEmiPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final upcomingEmisAsync = ref.watch(next3UpcomingEmisProvider);

    return upcomingEmisAsync.when(
      data: (emis) {
        if (emis.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No upcoming EMIs. You\'re all set!')),
            ),
          );
        }
        return Card(
          child: Column(
            children: List.generate(emis.length, (index) {
              final emi = emis[index];
              return Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.payment)),
                    title: Text(emi.loanName),
                    subtitle: Text(
                      'Due: ${AppFormatters.formatDate(emi.nextDueDate)}',
                    ),
                    trailing: Text(
                      AppFormatters.formatCurrency(
                          emi.monthlyEmiAmount, currency),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (index < emis.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('Error loading EMIs: $err')),
        ),
      ),
    );
  }
}
