import 'dart:ui'; // For Glassmorphism
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- 1. Modern Sliver App Bar ---
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 100.0,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Subscriptions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- 2. Subscription List ---
          subscriptionsAsync.when(
            data: (subs) {
              if (subs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.subscriptions_outlined,
                            size: 64,
                            color: theme.disabledColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No active subscriptions',
                          style: TextStyle(
                              fontSize: 18, color: theme.disabledColor),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = subs[index];
                      return _buildSubscriptionCard(
                          context, ref, sub, currency);
                    },
                    childCount: subs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),

          // Bottom Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // --- 3. Gradient FAB ---
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          onPressed: () => _showAddEditDialog(context, ref),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("New Sub",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- Premium Card Widget ---
  Widget _buildSubscriptionCard(
      BuildContext context, WidgetRef ref, Subscription sub, String currency) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _showAddEditDialog(context, ref, sub: sub),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat.MMMd().format(sub.nextDueDate)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(sub.amount, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _confirmDelete(context, ref, sub.id!),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.error.withOpacity(0.7)),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Modern Dialogs ---

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {Subscription? sub}) {
    final isEditing = sub != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: sub?.name);
    final amountController =
        TextEditingController(text: sub?.amount.toString());
    DateTime selectedDate = sub?.nextDueDate ?? DateTime.now();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              isEditing ? 'Edit Subscription' : 'New Subscription',
              style: const TextStyle(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name Input
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Service Name',
                            prefixIcon: Icon(Icons.label_outline_rounded,
                                color: theme.colorScheme.primary),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white10
                                : Colors.grey.withOpacity(0.1),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Amount Input
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Monthly Cost',
                            prefixIcon: Icon(Icons.attach_money_rounded,
                                color: theme.colorScheme.primary),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white10
                                : Colors.grey.withOpacity(0.1),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'))
                          ],
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Next Due Date:',
                                    style: theme.textTheme.bodyMedium),
                                Text(
                                  DateFormat.yMMMd().format(selectedDate),
                                  style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actionsPadding:
                const EdgeInsets.only(bottom: 24, left: 24, right: 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final subToSave = Subscription(
                      id: sub?.id,
                      name: nameController.text,
                      amount: double.parse(amountController.text),
                      nextDueDate: selectedDate,
                    );

                    final notifier =
                        ref.read(subscriptionListProvider.notifier);
                    if (isEditing) {
                      notifier.updateSubscription(subToSave);
                    } else {
                      notifier.addSubscription(subToSave);
                    }
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title:
                const Text('Remove Subscription?', textAlign: TextAlign.center),
            content: const Text(
              'This will remove it from your recurring bills list.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  ref
                      .read(subscriptionListProvider.notifier)
                      .deleteSubscription(id);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
