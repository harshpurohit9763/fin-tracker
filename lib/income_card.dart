import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/income_model.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

class IncomeCard extends ConsumerWidget {
  final Income income;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  income.description,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  AppFormatters.formatCurrency(
                      income.amount, ref.watch(currencyProvider)),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Source: ${income.source}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  AppFormatters.formatDate(income.date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (onEdit != null || onDelete != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                      tooltip: 'Edit Income',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                      tooltip: 'Delete Income',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
