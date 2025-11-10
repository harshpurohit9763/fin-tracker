import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/controllers/income_provider.dart'; // Will create this next

class AddIncomeScreen extends ConsumerStatefulWidget {
  final Income? income; // To edit existing income
  const AddIncomeScreen({super.key, this.income});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _sourceController; // Added source controller
  DateTime _selectedDate = DateTime.now();
  bool _isMonthly = false;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.income?.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.income?.description,
    );
    _sourceController = TextEditingController(
      text: widget.income?.source, // Initialize with existing source
    );
    if (_isEditing) {
      _selectedDate = widget.income!.date;
      _isMonthly = widget.income!.isMonthly;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose(); // Dispose source controller
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final source = _sourceController.text; // Get source value
      final monthYear = AppFormatters.formatMonthYear(_selectedDate);

      final newIncome = Income(
        id: widget.income?.id,
        amount: amount,
        description: description.isNotEmpty ? description : 'Income',
        source: source.isNotEmpty ? source : 'Other', // Default source
        date: _selectedDate,
        monthYear: monthYear,
        isMonthly: _isMonthly,
      );

      if (_isEditing) {
        await ref.read(incomeListProvider.notifier).updateIncome(newIncome);
      } else {
        await ref.read(incomeListProvider.notifier).addIncome(newIncome);
      }

      ref.invalidate(incomeListProvider);
      // Invalidate any dashboard providers that might display income

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Income' : 'Add Income')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Source
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  prefixIcon:
                      Icon(Icons.business_center), // Choose an appropriate icon
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a source';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton(onPressed: _pickDate, child: const Text('Change')),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Is Monthly Income
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monthly Income',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  Switch(
                    value: _isMonthly,
                    onChanged: (value) {
                      setState(() {
                        _isMonthly = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Update' : 'Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: textTheme.titleMedium,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
