// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:personal_finance/models/category_model.dart';
// import 'package:personal_finance/controllers/category_provider.dart';
// import 'package:personal_finance/controllers/insights_provider.dart';

// class ManageCategoriesScreen extends ConsumerStatefulWidget {
//   const ManageCategoriesScreen({super.key});

//   @override
//   ConsumerState<ManageCategoriesScreen> createState() =>
//       _ManageCategoriesScreenState();
// }

// class _ManageCategoriesScreenState
//     extends ConsumerState<ManageCategoriesScreen> {
//   bool _isSelectionMode = false;
//   final Set<int> _selectedCategories = {};

//   void _toggleSelection(int categoryId) {
//     setState(() {
//       if (_selectedCategories.contains(categoryId)) {
//         _selectedCategories.remove(categoryId);
//         if (_selectedCategories.isEmpty) {
//           _isSelectionMode = false;
//         }
//       } else {
//         _selectedCategories.add(categoryId);
//       }
//     });
//   }

//   void _enterSelectionMode(int categoryId) {
//     setState(() {
//       _isSelectionMode = true;
//       _selectedCategories.add(categoryId);
//     });
//   }

//   void _exitSelectionMode() {
//     setState(() {
//       _isSelectionMode = false;
//       _selectedCategories.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final categoriesAsync = ref.watch(categoryListProvider);

//     return Scaffold(
//       appBar: AppBar(
//         leading: _isSelectionMode
//             ? IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: _exitSelectionMode,
//               )
//             : null,
//         title: Text(_isSelectionMode
//             ? '${_selectedCategories.length} selected'
//             : 'Manage Categories'),
//         actions: _isSelectionMode
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => _confirmDeleteMultiple(context),
//                 ),
//               ]
//             : [],
//       ),
//       body: categoriesAsync.when(
//         data: (categories) {
//           if (categories.isEmpty) {
//             return const Center(child: Text('No categories found.'));
//           }
//           return ListView.builder(
//             itemCount: categories.length,
//             itemBuilder: (context, index) {
//               final category = categories[index];
//               final isSelected = _selectedCategories.contains(category.id!);
//               return ListTile(
//                 tileColor: isSelected
//                     ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
//                     : null,
//                 leading: _getCategoryTypeIcon(category.type),
//                 title: Text(category.name),
//                 onTap: () {
//                   if (_isSelectionMode) {
//                     _toggleSelection(category.id!);
//                   } else {
//                     _showEditCategoryTypeDialog(context, category);
//                   }
//                 },
//                 onLongPress: () {
//                   if (!_isSelectionMode) {
//                     _enterSelectionMode(category.id!);
//                   }
//                 },
//               );
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, stack) => Center(child: Text('Error: $err')),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddCategoryDialog(context),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _getCategoryTypeIcon(CategoryType type) {
//     switch (type) {
//       case CategoryType.Need:
//         return const Icon(Icons.shield_outlined, color: Colors.blue);
//       case CategoryType.Want:
//         return const Icon(Icons.shopping_bag_outlined, color: Colors.purple);
//       case CategoryType.Investment:
//         return const Icon(Icons.trending_up, color: Colors.green);
//       default:
//         return const Icon(Icons.circle_outlined);
//     }
//   }

//   void _confirmDeleteMultiple(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: Text('Delete ${_selectedCategories.length} Categories?'),
//         content: const Text(
//             'Are you sure you want to delete the selected categories? This will not affect existing expenses.'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: const Text('Cancel')),
//           TextButton(
//               onPressed: () {
//                 ref
//                     .read(categoryListProvider.notifier)
//                     .deleteMultipleCategories(_selectedCategories.toList());
//                 _exitSelectionMode();
//                 Navigator.of(dialogContext).pop();
//               },
//               child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );
//   }

//   void _confirmDelete(BuildContext context, Category category) {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Delete Category?'),
//           content: Text(
//               'Are you sure you want to delete the "${category.name}" category? This will not affect existing expenses.'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Delete', style: TextStyle(color: Colors.red)),
//               onPressed: () {
//                 ref
//                     .read(categoryListProvider.notifier)
//                     .deleteCategory(category.id!);
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showAddCategoryDialog(BuildContext context) {
//     final formKey = GlobalKey<FormState>();
//     final nameController = TextEditingController();
//     CategoryType selectedType = CategoryType.Want; // Default value

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text('Add New Category'),
//           content: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: 'Category Name'),
//                   autofocus: true,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter a category name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 DropdownButtonFormField<CategoryType>(
//                   value: selectedType,
//                   decoration: const InputDecoration(labelText: 'Category Type'),
//                   items: CategoryType.values
//                       .map((type) =>
//                           DropdownMenuItem(value: type, child: Text(type.name)))
//                       .toList(),
//                   onChanged: (value) {
//                     if (value != null) {
//                       selectedType = value;
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 if (formKey.currentState!.validate()) {
//                   final newCategory = Category(
//                     name: nameController.text.trim(),
//                     type: selectedType, // Include the selected type
//                   );
//                   try {
//                     await ref
//                         .read(categoryListProvider.notifier)
//                         .addCategory(newCategory);
//                     ref.invalidate(categoryListProvider);
//                     Navigator.of(dialogContext).pop();
//                   } catch (e) {
//                     Navigator.of(dialogContext).pop();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                           content: Text('Failed to add category: $e'),
//                           backgroundColor: Colors.red),
//                     );
//                   }
//                 }
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showEditCategoryTypeDialog(BuildContext context, Category category) {
//     CategoryType selectedType = category.type;
//     showDialog(
//         context: context,
//         builder: (dialogContext) {
//           return AlertDialog(
//             title: Text('Set Type for "${category.name}"'),
//             content: DropdownButtonFormField<CategoryType>(
//               value: selectedType,
//               items: CategoryType.values
//                   .map((type) =>
//                       DropdownMenuItem(value: type, child: Text(type.name)))
//                   .toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   selectedType = value;
//                 }
//               },
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(dialogContext).pop(),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   final updatedCategory = Category(
//                     id: category.id,
//                     name: category.name,
//                     type: selectedType,
//                   );
//                   await ref
//                       .read(categoryListProvider.notifier)
//                       .updateCategory(updatedCategory);
//                   ref.invalidate(spendingBreakdownProvider);
//                   Navigator.of(dialogContext).pop();
//                 },
//                 child: const Text('Save'),
//               )
//             ],
//           );
//         });
//   }
// }

import 'dart:ui'; // For Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/category_model.dart';
import 'package:personal_finance/controllers/category_provider.dart';
import 'package:personal_finance/controllers/insights_provider.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- 1. Modern App Bar ---
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 100.0,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelectionMode,
                  )
                : IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                _isSelectionMode
                    ? '${_selectedCategories.length} Selected'
                    : 'Manage Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteMultiple(context),
                    ),
                  ]
                : [],
          ),

          // --- 2. Category Grid ---
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No categories found.',
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4, // Rectangular cards
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final isSelected =
                          _selectedCategories.contains(category.id!);
                      return _buildCategoryCard(context, category, isSelected);
                    },
                    childCount: categories.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),

          // Bottom Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // --- 3. Gradient FAB ---
      floatingActionButton: _isSelectionMode
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text("New Category",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }

  // --- Premium Card Widget ---
  Widget _buildCategoryCard(
      BuildContext context, Category category, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color typeColor;
    String typeLabel;
    switch (category.type) {
      case CategoryType.Need:
        typeColor = Colors.blueAccent;
        typeLabel = "Need";
        break;
      case CategoryType.Want:
        typeColor = Colors.purpleAccent;
        typeLabel = "Want";
        break;
      case CategoryType.Investment:
        typeColor = Colors.tealAccent.shade700;
        typeLabel = "Invest";
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = "Other";
    }

    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
                width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 20),
              ],
            ),
            Text(
              category.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Modern Dialogs ---

  void _showAddCategoryDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    CategoryType selectedType = CategoryType.Want;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('New Category',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Category Name',
                          filled: true,
                          fillColor: isDark ? Colors.black12 : Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<CategoryType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          hintText: 'Type',
                          filled: true,
                          fillColor: isDark ? Colors.black12 : Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        items: CategoryType.values
                            .map((type) => DropdownMenuItem(
                                value: type, child: Text(type.name)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null)
                            setState(() => selectedType = value);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newCategory = Category(
                      name: nameController.text.trim(),
                      type: selectedType,
                    );
                    try {
                      await ref
                          .read(categoryListProvider.notifier)
                          .addCategory(newCategory);
                      ref.invalidate(categoryListProvider);
                      if (mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      // Handle error
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCategoryTypeDialog(BuildContext context, Category category) {
    CategoryType selectedType = category.type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Edit "${category.name}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: DropdownButtonFormField<CategoryType>(
              value: selectedType,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.black12 : Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: CategoryType.values
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedType = value;
              },
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
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
                  if (mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              )
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteMultiple(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Delete ${_selectedCategories.length} Categories?',
              textAlign: TextAlign.center),
          content: const Text(
            'Are you sure? This will NOT delete existing expenses, but may affect reports.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(categoryListProvider.notifier)
                    .deleteMultipleCategories(_selectedCategories.toList());
                _exitSelectionMode();
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
