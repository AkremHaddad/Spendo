import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../data/models/category.dart';
import '../../../core/theme/theme.dart';

const List<Color> kCategoryColors = [
  Color(0xFFF44336),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF673AB7),
  Color(0xFF3F51B5),
  Color(0xFF2196F3),
  Color(0xFF03A9F4),
  Color(0xFF00BCD4),
  Color(0xFF009688),
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFFCDDC39),
  Color(0xFFFFEB3B),
  Color(0xFFFFC107),
  Color(0xFFFF9800),
  Color(0xFFFF5722),
  Color(0xFF795548),
  Color(0xFF9E9E9E),
  Color(0xFF607D8B),
  Color(0xFF000000),
];

class CategoryDetailDialog {
  /// Show category detail dialog
  static void showCategoryDetailDialog(
    BuildContext context,
    Category category,
  ) {
    final nameController = TextEditingController(text: category.name);
    final productInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            final theme = Theme.of(ctx2);

            void _addProduct() {
              final productName = productInputController.text.trim();
              if (productName.isEmpty) return;
              context.read<CategoryNotifier>().addProduct(
                category.id,
                productName,
              );
              productInputController.clear();
              setState(() {});
            }

            void _editProduct(String productId, String currentName) async {
              final controller = TextEditingController(text: currentName);
              final newName = await showDialog<String>(
                context: ctx2,
                builder: (_) => AlertDialog(
                  title: const Text('Edit Product Name'),
                  content: TextField(controller: controller),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).baseContent,
                      ),
                      onPressed: () => Navigator.pop(ctx2, null),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).primaryContent,
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx2, controller.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (newName != null && newName.isNotEmpty) {
                context.read<CategoryNotifier>().editProduct(
                  category.id,
                  productId,
                  newName,
                );
                setState(() {});
              }
            }

            Future<void> _confirmDeleteProduct(String productId) async {
              final confirmed = await showDialog<bool>(
                context: ctx2,
                builder: (confirmCtx) => AlertDialog(
                  title: const Text("Delete Product"),
                  content: const Text(
                    "Are you sure you want to delete this product?",
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).baseContent,
                      ),
                      onPressed: () => Navigator.pop(confirmCtx, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: () => Navigator.pop(confirmCtx, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                context.read<CategoryNotifier>().softDeleteProduct(
                  category.id,
                  productId,
                );
                setState(() {});
              }
            }

            Future<void> _confirmDeleteCategory() async {
              final confirmed = await showDialog<bool>(
                context: ctx2,
                builder: (confirmCtx) => AlertDialog(
                  title: const Text("Delete Category"),
                  content: const Text(
                    "Are you sure you want to delete this category?",
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).baseContent,
                      ),
                      onPressed: () => Navigator.pop(confirmCtx, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: () => Navigator.pop(confirmCtx, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                context.read<CategoryNotifier>().softDeleteCategory(
                  category.id,
                );
                Navigator.pop(ctx2);
              }
            }

            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width < 600
                      ? MediaQuery.of(context).size.width * 0.9
                      : 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Edit button
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).white, // different bg for button
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(ctx2).primaryColor,
                              ),
                              onPressed: () async {
                                final controller = TextEditingController(
                                  text: category.name,
                                );
                                final newName = await showDialog<String>(
                                  context: ctx2,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Edit Category Name'),
                                    content: TextField(controller: controller),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(
                                            ctx2,
                                          ).baseContent,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx2, null),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            ctx2,
                                          ).primaryColor,
                                          foregroundColor: Theme.of(
                                            ctx2,
                                          ).primaryContent,
                                        ),
                                        onPressed: () => Navigator.pop(
                                          ctx2,
                                          controller.text.trim(),
                                        ),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (newName != null && newName.isNotEmpty) {
                                  context.read<CategoryNotifier>().editCategory(
                                    category.id,
                                    name: newName,
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          // Delete button
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).white, 
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _confirmDeleteCategory,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Products list
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Theme.of(context).base300,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: category.products
                                .where((p) => !p.isDeleted)
                                .map((p) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).base100,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.shadowColor.withOpacity(
                                            0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          onPressed: () =>
                                              _editProduct(p.id, p.name),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Theme.of(
                                              context,
                                            ).error,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteProduct(p.id),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ),

                    // Add product row
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: productInputController,
                                decoration: InputDecoration(
                                  labelText: 'New Product',
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                ),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                                onSubmitted: (_) => _addProduct(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Theme.of(
                                  context,
                                ).primaryContent,
                              ),
                              onPressed: _addProduct,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show dialog to add a new category
  static void showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = kCategoryColors.first;
    CategoryType selectedType = CategoryType.expense;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) {
          final theme = Theme.of(ctx2);

          return AlertDialog(
            title: const Text("Add Category"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      filled: true,
                      fillColor: Theme.of(context).base200,
                    ),
                    style: TextStyle(color: Theme.of(context).baseContent),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Color"),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: GridView.count(
                      crossAxisCount: 10,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: kCategoryColors.map((c) {
                        final isSelected = c == selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<CategoryType>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: CategoryType.expense,
                        child: Text("Expense"),
                      ),
                      DropdownMenuItem(
                        value: CategoryType.income,
                        child: Text("Income"),
                      ),
                    ],
                    onChanged: (t) => setState(() => selectedType = t!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).primaryContent,
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    context.read<CategoryNotifier>().addCategory(
                      name,
                      selectedColor,
                      selectedType,
                    );
                    Navigator.pop(ctx2);
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }
}
