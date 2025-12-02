import 'package:flutter/material.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/helper/app_formater.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback? onTap;
  // final VoidCallback? onDelete; // Removed onDelete for this refactor

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.currency,
    this.onTap,
    // this.onDelete, // Removed onDelete for this refactor
  });

  @override
  Widget build(BuildContext context) {
    if (expense.transactionType == 'EMI' && expense.scheduledAmount != null) {
      final difference = expense.amount - expense.scheduledAmount!;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          margin: const EdgeInsets.only(bottom: 12.0), // Added margin for spacing
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.description ?? 'Credit Card EMI Payment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paid on: ${AppFormatters.formatDate(expense.date)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                context,
                'Original EMI:',
                AppFormatters.formatCurrency(expense.scheduledAmount!, currency),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Amount Paid:',
                AppFormatters.formatCurrency(expense.amount, currency),
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Difference:',
                AppFormatters.formatCurrency(difference, currency),
                isBold: true,
                valueColor: difference == 0
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : difference > 0
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary, // Using primary for positive difference
              ),
            ],
          ),
        ),
      );
    }

    // Default view for other expenses
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.only(bottom: 12.0),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description ?? expense.category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expense.category} on ${AppFormatters.formatDate(expense.date)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              AppFormatters.formatCurrency(expense.amount, currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}
