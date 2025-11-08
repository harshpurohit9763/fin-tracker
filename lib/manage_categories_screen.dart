import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/category_model.dart';
import 'package:personal_finance/category_provider.dart';
import 'package:personal_finance/insights_provider.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedCategories = {};

  void _toggleSelection(int categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
        if (_selectedCategories.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  void _enterSelectionMode(int categoryId) {
    setState(() {
      _isSelectionMode = true;
      _selectedCategories.add(categoryId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(_isSelectionMode
            ? '${_selectedCategories.length} selected'
            : 'Manage Categories'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteMultiple(context),
                ),
              ]
            : [],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategories.contains(category.id!);
              return ListTile(
                tileColor: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : null,
                leading: _getCategoryTypeIcon(category.type),
                title: Text(category.name),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(category.id!);
                  } else {
                    _showEditCategoryTypeDialog(context, category);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(category.id!);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getCategoryTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.Need:
        return const Icon(Icons.shield_outlined, color: Colors.blue);
      case CategoryType.Want:
        return const Icon(Icons.shopping_bag_outlined, color: Colors.purple);
      case CategoryType.Investment:
        return const Icon(Icons.trending_up, color: Colors.green);
      default:
        return const Icon(Icons.circle_outlined);
    }
  }

  void _confirmDeleteMultiple(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${_selectedCategories.length} Categories?'),
        content: const Text(
            'Are you sure you want to delete the selected categories? This will not affect existing expenses.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                ref
                    .read(categoryListProvider.notifier)
                    .deleteMultipleCategories(_selectedCategories.toList());
                _exitSelectionMode();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category?'),
          content: Text(
              'Are you sure you want to delete the "${category.name}" category? This will not affect existing expenses.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                ref
                    .read(categoryListProvider.notifier)
                    .deleteCategory(category.id!);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newCategory =
                      Category(name: nameController.text.trim());
                  try {
                    await ref
                        .read(categoryListProvider.notifier)
                        .addCategory(newCategory);
                    ref.invalidate(categoryListProvider);
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to add category: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryTypeDialog(BuildContext context, Category category) {
    CategoryType selectedType = category.type;
    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Set Type for "${category.name}"'),
            content: DropdownButtonFormField<CategoryType>(
              value: selectedType,
              items: CategoryType.values
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedType = value;
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedCategory = Category(
                    id: category.id,
                    name: category.name,
                    type: selectedType,
                  );
                  await ref
                      .read(categoryListProvider.notifier)
                      .updateCategory(updatedCategory);
                  ref.invalidate(spendingBreakdownProvider);
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              )
            ],
          );
        });
  }
}
