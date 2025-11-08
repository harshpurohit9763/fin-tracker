import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/emi_model.dart';
import 'package:personal_finance/dashboard_provider.dart';
import 'package:personal_finance/emi_provider.dart';

class AddEmiScreen extends ConsumerStatefulWidget {
  final Emi? emi; // To edit existing EMI
  const AddEmiScreen({super.key, this.emi});

  @override
  ConsumerState<AddEmiScreen> createState() => _AddEmiScreenState();
}

class _AddEmiScreenState extends ConsumerState<AddEmiScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _loanNameController;
  late TextEditingController _bankNameController;
  late TextEditingController _amountController;
  late TextEditingController _interestRateController;
  late TextEditingController _tenureController;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.emi != null;

  // Custom tenure field for editing
  late TextEditingController _tenureRemainingController;

  @override
  void initState() {
    super.initState();
    _loanNameController = TextEditingController(text: widget.emi?.loanName);
    _bankNameController = TextEditingController(text: widget.emi?.bankName);
    _amountController = TextEditingController(
      text: widget.emi?.monthlyEmiAmount.toString(),
    );
    _interestRateController = TextEditingController(
      text: widget.emi?.interestRate.toString(),
    );
    _tenureController = TextEditingController(
      text: widget.emi?.totalTenureMonths.toString(),
    );
    _tenureRemainingController = TextEditingController(
      text: widget.emi?.tenureRemainingMonths.toString(),
    );

    if (_isEditing) {
      _selectedDate = widget.emi!.nextDueDate;
    }
  }

  @override
  void dispose() {
    _loanNameController.dispose();
    _bankNameController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _tenureRemainingController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newEmi = Emi(
        id: widget.emi?.id,
        loanName: _loanNameController.text,
        bankName: _bankNameController.text.isNotEmpty
            ? _bankNameController.text
            : null,
        monthlyEmiAmount: double.parse(_amountController.text),
        interestRate: _interestRateController.text.isNotEmpty
            ? double.parse(_interestRateController.text)
            : null,
        totalTenureMonths: int.parse(_tenureController.text),
        tenureRemainingMonths: _isEditing
            ? int.parse(
                _tenureRemainingController.text,
              ) // Use remaining if editing
            : int.parse(_tenureController.text), // Use total if new
        nextDueDate: _selectedDate,
      );

      if (_isEditing) {
        await ref.read(emiListProvider.notifier).updateEmi(newEmi);
      } else {
        await ref.read(emiListProvider.notifier).addEmi(newEmi);
      }

      ref.invalidate(emiListProvider);
      ref.invalidate(upcomingEmisThisWeekCountProvider);
      ref.invalidate(next3UpcomingEmisProvider);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit EMI' : 'Add EMI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _loanNameController,
                decoration: const InputDecoration(
                  labelText: 'Loan Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a loan name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monthly EMI Amount *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter an amount'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestRateController,
                decoration: const InputDecoration(
                  labelText: 'Interest Rate % (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenureController,
                decoration: const InputDecoration(
                  labelText: 'Total Tenure (in months) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter total tenure'
                    : null,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tenureRemainingController,
                  decoration: const InputDecoration(
                    labelText: 'Tenure Remaining (in months) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter remaining tenure'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Next Due Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton(onPressed: _pickDate, child: const Text('Change')),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Update EMI' : 'Save EMI'),
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
