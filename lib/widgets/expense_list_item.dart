import 'package:flutter/material.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/helper/app_formater.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.currency,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (expense.transactionType == 'EMI' && expense.scheduledAmount != null) {
      // Special view for EMI transactions
      final difference = expense.amount - expense.scheduledAmount!;
      return Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.description ?? 'EMI Payment',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: onDelete,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid on: ${AppFormatters.formatDate(expense.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Original EMI:'),
                    Text(AppFormatters.formatCurrency(
                        expense.scheduledAmount!, currency)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Paid:'),
                    Text(
                      AppFormatters.formatCurrency(expense.amount, currency),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Difference:'),
                    Text(
                      AppFormatters.formatCurrency(difference, currency),
                      style: TextStyle(
                        color: difference == 0
                            ? Colors.grey
                            : difference > 0
                                ? Colors.red
                                : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default view for other expenses
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(AppFormatters.formatCurrency(expense.amount, currency)),
        subtitle: Text(
            '${expense.category} on ${AppFormatters.formatDate(expense.date)}'),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}

