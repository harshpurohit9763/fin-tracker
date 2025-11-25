import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/helper/tflite_helper.dart';
import 'package:personal_finance/models/category_model.dart';
import 'package:personal_finance/controllers/category_provider.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/controllers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense; // To edit existing expense
  const AddExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TFLiteHelper? _tfliteHelper;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description,
    );
    _tfliteHelper = TFLiteHelper();
    if (_isEditing) {
      _selectedDate = widget.expense!.date;
      // Note: _selectedCategory will be set when the category list loads
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _tfliteHelper?.close();
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

  Future<void> _pickAndProcessImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final recognizedText = await _tfliteHelper?.predict(bytes);
      if (recognizedText != null) {
        // Simple parsing logic, assuming amount is a number in the text
        final RegExp amountRegex = RegExp(r'(\d+\.\d{2})');
        final match = amountRegex.firstMatch(recognizedText);
        if (match != null) {
          _amountController.text = match.group(1)!;
        }
        setState(() {
          _descriptionController.text = recognizedText;
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final monthYear = AppFormatters.formatMonthYear(_selectedDate);

      final newExpense = Expense(
        id: widget.expense?.id,
        amount: amount,
        category: _selectedCategory!.name,
        date: _selectedDate,
        monthYear: monthYear,
        description: description.isNotEmpty ? description : null,
      );

      if (_isEditing) {
        await ref.read(expenseListProvider.notifier).updateExpense(newExpense);
      } else {
        await ref.read(expenseListProvider.notifier).addExpense(newExpense);
      }

      ref.invalidate(expenseListProvider);
      ref.invalidate(currentMonthSpendingProvider);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoryListProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _pickAndProcessImage,
            tooltip: 'Extract from bill',
          ),
        ],
      ),
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

              // Category
              categoriesAsyncValue.when(
                data: (categories) {
                  // If editing, find the category object that matches the name
                  if (_isEditing && _selectedCategory == null) {
                    _selectedCategory = categories.firstWhere(
                      (c) => c.name == widget.expense!.category,
                      orElse: () => categories.first,
                    );
                  }

                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((Category category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading categories: $err'),
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
