import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/emi_model.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart'; // Import isAmoledProvider
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class AddEmiScreen extends ConsumerStatefulWidget {
  final Emi? emi;
  const AddEmiScreen({super.key, this.emi});

  @override
  ConsumerState<AddEmiScreen> createState() => _AddEmiScreenState();
}

class _AddEmiScreenState extends ConsumerState<AddEmiScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _loanNameController;
  late TextEditingController _emiAmountController;
  late TextEditingController _tenureController;
  late TextEditingController _bankNameController;
  late TextEditingController _interestRateController;
  DateTime _startDate = DateTime.now();
  bool _isCompoundInterest = false;

  bool get _isEditing => widget.emi != null;

  @override
  void initState() {
    super.initState();
    _loanNameController = TextEditingController(text: widget.emi?.loanName);
    _emiAmountController = TextEditingController(
        text: widget.emi?.monthlyEmiAmount.toString() ?? '');
    _tenureController = TextEditingController(
        text: widget.emi?.totalTenureMonths.toString() ?? '');
    _bankNameController = TextEditingController(text: widget.emi?.bankName);
    _interestRateController =
        TextEditingController(text: widget.emi?.interestRate?.toString() ?? '');

    if (_isEditing) {
      _startDate = widget.emi!.startDate;
      _isCompoundInterest = widget.emi!.isCompoundInterest;
    }
  }

  @override
  void dispose() {
    _loanNameController.dispose();
    _emiAmountController.dispose();
    _tenureController.dispose();
    _bankNameController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    onPrimary: Colors.white,
                  )),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _startDate) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final loanName = _loanNameController.text;
      final emiAmount = double.parse(_emiAmountController.text);
      final totalTenure = int.parse(_tenureController.text);
      final bankName = _bankNameController.text;
      final interestRate = double.tryParse(_interestRateController.text);

      final Emi emiToSave;

      if (_isEditing) {
        // When editing, we only update the core details.
        // The state (remaining tenure, next due date) is managed by "Mark as Paid".
        emiToSave = widget.emi!.copyWith(
          loanName: loanName,
          monthlyEmiAmount: emiAmount,
          startDate: _startDate,
          totalTenureMonths: totalTenure,
          bankName: bankName.isNotEmpty ? bankName : null,
          interestRate: interestRate,
          isCompoundInterest: _isCompoundInterest,
        );
      } else {
        // For a new loan, we set the initial state.
        emiToSave = Emi(
          loanName: loanName,
          monthlyEmiAmount: emiAmount,
          startDate: _startDate,
          totalTenureMonths: totalTenure,
          tenureRemainingMonths: totalTenure,
          nextDueDate:
              DateTime(_startDate.year, _startDate.month + 1, _startDate.day),
          bankName: bankName.isNotEmpty ? bankName : null,
          interestRate: interestRate,
          isCompoundInterest: _isCompoundInterest,
        );
      }

      if (_isEditing) {
        await ref.read(emiListProvider.notifier).updateEmi(emiToSave);
      } else {
        await ref.read(emiListProvider.notifier).addEmi(emiToSave);
      }

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = ref.watch(isAmoledProvider); // Watch isAmoledProvider
    final currency = ref.watch(currencyProvider);

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
      backgroundColor: isAmoled ? Colors.black : theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Loan' : 'New Loan',
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
              // --- Hero Amount Field ---
              Center(
                child: Column(
                  children: [
                    Text(
                      'Monthly EMI Amount',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _emiAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '$currency ',
                          prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: theme.disabledColor.withOpacity(0.3),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required'
                            : (double.tryParse(v) == null ? 'Invalid' : null),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- Details Card ---
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
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
                    TextFormField(
                      controller: _loanNameController,
                      decoration: getModernInputDecoration(
                          'Loan Name (e.g. Car Loan)', Icons.label_rounded),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _bankNameController,
                      decoration: getModernInputDecoration(
                          'Bank Name (Optional)',
                          Icons.account_balance_rounded),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _interestRateController,
                      decoration: getModernInputDecoration(
                          'Interest Rate % (Optional)', Icons.percent_rounded),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tenureController,
                      decoration: getModernInputDecoration(
                          'Total Tenure (in months)', Icons.timelapse_rounded),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
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
                            Text(
                              'Start Date: ${DateFormat.yMMMd().format(_startDate)}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Use Compound Interest Formula'),
                      subtitle: const Text(
                          'Calculates liability based on outstanding principal. Turn off for simple interest calculation.'),
                      value: _isCompoundInterest,
                      onChanged: (bool value) {
                        setState(() {
                          _isCompoundInterest = value;
                        });
                      },
                      secondary: Icon(Icons.calculate_rounded,
                          color: colorScheme.primary.withOpacity(0.7)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- Submit Button ---
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitForm,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Text(
                        _isEditing ? 'Update Loan' : 'Save Loan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
