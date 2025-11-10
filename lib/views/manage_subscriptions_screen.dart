import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/models/subscription_model.dart';
import 'package:personal_finance/controllers/subscription_provider.dart';

class ManageSubscriptionsScreen extends ConsumerWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionListProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscriptions'),
      ),
      body: subscriptionsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return const Center(child: Text('No subscriptions added yet.'));
          }
          return ListView.builder(
            itemCount: subs.length,
            itemBuilder: (context, index) {
              final sub = subs[index];
              return ListTile(
                title: Text(sub.name),
                subtitle: Text(
                    'Next due: ${AppFormatters.formatDate(sub.nextDueDate)}'),
                trailing:
                    Text(AppFormatters.formatCurrency(sub.amount, currency)),
                onTap: () => _showAddEditDialog(context, ref, sub: sub),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {Subscription? sub}) {
    final isEditing = sub != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: sub?.name);
    final amountController =
        TextEditingController(text: sub?.amount.toString());
    DateTime selectedDate = sub?.nextDueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Subscription' : 'Add Subscription'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Service Name'),
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter a name' : null,
                      ),
                      TextFormField(
                        controller: amountController,
                        decoration:
                            const InputDecoration(labelText: 'Monthly Cost'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter an amount' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                                'Next Due: ${DateFormat.yMMMd().format(selectedDate)}'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final subToSave = Subscription(
                    id: sub?.id,
                    name: nameController.text,
                    amount: double.parse(amountController.text),
                    nextDueDate: selectedDate,
                  );

                  final notifier = ref.read(subscriptionListProvider.notifier);
                  if (isEditing) {
                    notifier.updateSubscription(subToSave);
                  } else {
                    notifier.addSubscription(subToSave);
                  }

                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
