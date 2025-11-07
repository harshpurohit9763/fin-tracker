import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/category_model.dart';
import 'package:offline_expense_tracker/category_provider.dart';
import 'package:offline_expense_tracker/insights_provider.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
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
              return ListTile(
                leading: _getCategoryTypeIcon(category.type),
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref, category),
                ),
                onTap: () =>
                    _showEditCategoryTypeDialog(context, ref, category),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
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

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
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

  void _showEditCategoryTypeDialog(
      BuildContext context, WidgetRef ref, Category category) {
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
