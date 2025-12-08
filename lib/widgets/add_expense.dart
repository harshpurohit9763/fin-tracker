import 'dart:io';
import 'dart:ui'; // For image filters if needed
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
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
      text: widget.expense?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description,
    );
    _tfliteHelper = TFLiteHelper();
    if (_isEditing) {
      _selectedDate = widget.expense!.date;
      // Note: _selectedCategory will be set when the category list loads in build
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickAndProcessImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Show loading feedback if desired
        final bytes = await image.readAsBytes();
        final recognizedText = await _tfliteHelper?.predict(bytes);
        if (recognizedText != null) {
          // Simple parsing logic
          final RegExp amountRegex = RegExp(r'(\d+\.\d{2})');
          final match = amountRegex.firstMatch(recognizedText);
          if (match != null) {
            _amountController.text = match.group(1)!;
          }
          setState(() {
            _descriptionController.text = recognizedText;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt scanned successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning receipt: $e')),
        );
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a category'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final monthYear = AppFormatters.formatMonthYear(_selectedDate);

      if (_isEditing) {
        final updatedExpense = widget.expense!.copyWith(
          amount: amount,
          category: _selectedCategory!.name,
          date: _selectedDate,
          monthYear: monthYear,
          description: description.isNotEmpty ? description : null,
        );
        await ref
            .read(expenseListProvider.notifier)
            .updateExpense(updatedExpense);
      } else {
        final newExpense = Expense(
          amount: amount,
          category: _selectedCategory!.name,
          date: _selectedDate,
          monthYear: monthYear,
          description: description.isNotEmpty ? description : null,
        );
        await ref.read(expenseListProvider.notifier).addExpense(newExpense);
      }

      ref.invalidate(currentMonthSpendingProvider);

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAmoled = ref.watch(isAmoledProvider); // Watch isAmoledProvider
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    // Check if this is an EMI expense to disable certain fields
    final bool isEmiExpense =
        _isEditing && widget.expense?.transactionType == 'EMI';

    // Helper for input decoration
    InputDecoration getModernInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    }

    return Scaffold(
      backgroundColor: isAmoled
          ? Colors.black
          : (isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA)),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'New Expense',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Hero Amount & Scanner ---
              Center(
                child: Column(
                  children: [
                    Text(
                      isEmiExpense ? 'EMI Amount' : 'Amount Spent',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              colorScheme.error, // Red/Error color for expenses
                        ),
                        decoration: InputDecoration(
                          prefixText:
                              '$currency ', // Dynamic currency symbol ideally
                          prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.error.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: theme.disabledColor.withOpacity(0.3),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scan Receipt Pill Button
                    InkWell(
                      onTap: _pickAndProcessImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Record Receipt",
                              style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- 2. Details Card ---
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Category Dropdown
                    categoriesAsyncValue.when(
                      data: (categories) {
                        // Logic to pre-select category on edit
                        if (_isEditing && _selectedCategory == null) {
                          try {
                            _selectedCategory = categories.firstWhere(
                              (c) => c.name == widget.expense!.category,
                            );
                          } catch (e) {
                            _selectedCategory =
                                categories.isNotEmpty ? categories.first : null;
                          }
                        }

                        return DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: getModernInputDecoration(
                              'Category', Icons.category_rounded),
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          borderRadius: BorderRadius.circular(16),
                          dropdownColor:
                              isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          items: categories.map((Category category) {
                            return DropdownMenuItem<Category>(
                              value: category,
                              child: Row(
                                children: [
                                  // Optional: Add circle color if category has color
                                  Text(category.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isEmiExpense
                              ? null // Disable category change for EMI
                              : (Category? newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                          validator: (value) =>
                              value == null ? 'Please select a category' : null,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => Text('Error: $err',
                          style: const TextStyle(color: Colors.red)),
                    ),

                    const SizedBox(height: 20),

                    // Date Picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: colorScheme.primary.withOpacity(0.7)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: theme.hintColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.yMMMd().format(_selectedDate),
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down_rounded),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: getModernInputDecoration(
                          'Description (Optional)', Icons.notes_rounded),
                      maxLines: 2,
                    ),

                    // EMI Specific Field (Read Only)
                    if (isEmiExpense) ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        initialValue:
                            widget.expense?.scheduledAmount?.toString() ??
                                '0.0',
                        readOnly: true,
                        decoration: getModernInputDecoration(
                                'Scheduled EMI Amount', Icons.schedule_rounded)
                            .copyWith(
                          fillColor: theme.disabledColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 3. Submit Button ---
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitForm,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _isEditing
                                  ? Icons.check_circle_outline
                                  : Icons.add_circle_outline,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            _isEditing ? 'Update Expense' : 'Save Expense',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
