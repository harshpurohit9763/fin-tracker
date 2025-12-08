import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:personal_finance/controllers/goal_provider.dart';
import 'package:personal_finance/views/goal_model.dart';

final Map<String, IconData> goalIcons = {
  'savings': Icons.savings_outlined,
  'car': Icons.directions_car_outlined,
  'house': Icons.house_outlined,
  'vacation': Icons.beach_access_outlined,
  'education': Icons.school_outlined,
  'gadget': Icons.phone_iphone_outlined,
  'gift': Icons.card_giftcard_outlined,
  'other': Icons.star_border_outlined,
};

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;
  const AddEditGoalScreen({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  String _selectedIcon = 'other';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetAmountController =
        TextEditingController(text: widget.goal?.targetAmount.toString() ?? '');
    if (widget.goal != null) {
      _targetDate = widget.goal!.targetDate;
      _selectedIcon = widget.goal!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final targetAmount = double.tryParse(_targetAmountController.text) ?? 0.0;

      final goal = Goal(
        id: widget.goal?.id,
        name: name,
        targetAmount: targetAmount,
        currentAmount: widget.goal?.currentAmount ?? 0.0,
        targetDate: _targetDate,
        icon: _selectedIcon,
      );

      if (widget.goal == null) {
        ref.read(goalListProvider.notifier).addGoal(goal);
      } else {
        ref.read(goalListProvider.notifier).updateGoal(goal);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Helper for inputs
    InputDecoration getDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: theme.colorScheme.primary.withOpacity(0.7)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
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
        centerTitle: true,
        title: Text(
          widget.goal == null ? 'New Goal' : 'Edit Goal',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Name Input ---
              TextFormField(
                controller: _nameController,
                decoration: getDecoration('Goal Name', Icons.flag_rounded),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 20),

              // --- Amount Input ---
              TextFormField(
                controller: _targetAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    getDecoration('Target Amount', Icons.track_changes_rounded),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                ],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter amount';
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Date Picker ---
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: theme.colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target Date',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.hintColor)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd().format(_targetDate),
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

              const SizedBox(height: 32),

              // --- Icon Selector ---
              Text(
                'Choose Icon',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: goalIcons.length,
                itemBuilder: (context, index) {
                  final key = goalIcons.keys.elementAt(index);
                  final icon = goalIcons[key]!;
                  final isSelected = _selectedIcon == key;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]
                              : [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2))
                                ],
                          border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : theme.dividerColor.withOpacity(0.1))),
                      child: Icon(
                        icon,
                        size: 28,
                        color:
                            isSelected ? Colors.white : theme.iconTheme.color,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // --- Save Button ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.goal == null ? 'Create Goal' : 'Save Changes',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
