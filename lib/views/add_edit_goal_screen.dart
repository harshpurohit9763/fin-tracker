import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  DateTime _targetDate = DateTime.now();
  String _selectedIcon = 'other';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetAmountController =
        TextEditingController(text: widget.goal?.targetAmount.toString() ?? '');
    _targetDate = widget.goal?.targetDate ??
        DateTime.now().add(const Duration(days: 365));
    _selectedIcon = widget.goal?.icon ?? 'other';
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
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveGoal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your goal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                title: Text(
                    'Target Date: ${MaterialLocalizations.of(context).formatFullDate(_targetDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24),
              Text('Select an Icon',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
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
                    onTap: () {
                      setState(() {
                        _selectedIcon = key;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
