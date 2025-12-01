import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/emi_model.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/widgets/upcoming_emi_card.dart';

class FlippableEmiCard extends StatefulWidget {
  final Emi emi;
  final String currency;
  final String userName;
  final VoidCallback onProfileTap;

  const FlippableEmiCard({
    super.key,
    required this.emi,
    required this.currency,
    required this.userName,
    required this.onProfileTap,
  });

  @override
  State<FlippableEmiCard> createState() => _FlippableEmiCardState();
}

class _FlippableEmiCardState extends State<FlippableEmiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _markAsPaid(BuildContext context, WidgetRef ref) {
    final amountController =
        TextEditingController(text: widget.emi.monthlyEmiAmount.toString());
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm EMI Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the amount paid for ${widget.emi.loanName}.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                final paidAmount = double.tryParse(amountController.text);
                if (paidAmount != null && paidAmount > 0) {
                  ref
                      .read(emiListProvider.notifier)
                      .markEmiAsPaidWithAmount(widget.emi, paidAmount);
                  Navigator.of(dialogContext).pop();
                  // Flip back after action
                  _handleTap();
                } else {
                  // Optionally, show a validation error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * -pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _isFront
                ? UpcomingEmiCard(
                    emi: widget.emi,
                    currency: widget.currency,
                    userName: widget.userName,
                    onProfileTap: widget.onProfileTap,
                  )
                : Transform(
                    transform: Matrix4.identity()
                      ..rotateY(pi), // Flip back view
                    alignment: Alignment.center,
                    child: _buildCardBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Center(
              child: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      backgroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    onPressed: () => _markAsPaid(context, ref),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
