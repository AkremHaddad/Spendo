import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../data/models/category.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';

const List<Color> kCategoryColors = [
  Color.fromARGB(255, 212, 33, 30), // Red
  Color(0xFFEF5350), // Light Red
  Color(0xFFD81B60), // Pink

  Color(0xFFFF6F00), // Orange
  Color(0xFFFB8C00), // Deep Orange

  Color(0xFFFDD835), // Yellow
  Color(0xFFC0CA33), // Lime
  Color(0xFF9E9D24), // Olive

  Color(0xFF7CB342), // Light Green
  Color(0xFF43A047), // Green
  Color(0xFF00897B), // Teal

  Color(0xFF00ACC1), // Cyan
  Color(0xFF42A5F5), // Light Blue
  Color(0xFF1E88E5), // Blue
  Color(0xFF3949AB), // Indigo

  Color(0xFF5E35B1), // Deep Purple
  Color(0xFF8E24AA), // Purple

  Color(0xFF6D4C41), // Brown
  Color(0xFF546E7A), // Blue Grey
  Color(0xFF000000), // Black
];

class CategoryDetailDialog {
  /// Show category detail dialog
  static void showCategoryDetailDialog(
    BuildContext context,
    Category category,
  ) {
    final productInputController = TextEditingController();
    final isMobileView = isMobile(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<CategoryNotifier>(
          builder: (ctx2, notifier, _) {
            // latestCategory may become null if it was deleted
            final latestCategory = notifier.getCategoryById(category.id);

            // If category was deleted, close the dialog safely.
            if (latestCategory == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final nav = Navigator.of(ctx2);
                if (nav.mounted && nav.canPop()) nav.pop();
              });
              return const SizedBox.shrink();
            }

            final theme = Theme.of(ctx2);

            void _addProduct() {
              final productName = productInputController.text.trim();
              if (productName.isEmpty) return;
              notifier.addProduct(latestCategory.id, productName);
              productInputController.clear();
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
                notifier.editProduct(latestCategory.id, productId, newName);
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
                notifier.softDeleteProduct(latestCategory.id, productId);
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
                        foregroundColor: theme.colorScheme.onSurface,
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
                final success = await notifier.softDeleteCategory(
                  latestCategory.id,
                );
                if (success) {
                  final nav = Navigator.of(ctx2);
                  if (nav.mounted && nav.canPop()) nav.pop();
                } else {
                  // show a non-crashing error indicator
                  if (ScaffoldMessenger.maybeOf(ctx2) != null) {
                    ScaffoldMessenger.of(ctx2).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete category'),
                      ),
                    );
                  }
                }
              }
            }

            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width < 600
                      ? MediaQuery.of(context).size.width * 0.9
                      : 500,
                  maxHeight: !isMobileView ? MediaQuery.of(context).size.height * 0.85 : MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: latestCategory.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                // Stroke / Border
                                Text(
                                  latestCategory.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 2
                                      ..color = Colors.black, // border color
                                  ),
                                ),
                                // Fill
                                Text(
                                  latestCategory.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // text fill color
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit button
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).white, // different bg for button
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(ctx2).baseContent,
                              ),
                              onPressed: () async {
                                final nameController = TextEditingController(
                                  text: latestCategory.name,
                                );
                                Color selectedColor = latestCategory
                                    .color; // pre-fill with current color

                                final result = await showDialog<Map<String, dynamic>>(
                                  context: ctx2,
                                  builder: (_) => StatefulBuilder(
                                    builder: (ctx2, setState) {
                                      final theme = Theme.of(ctx2);

                                      return AlertDialog(
                                        title: const Text('Edit Category'),
                                        content: SizedBox(
                                          width: 400,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Name input
                                              TextField(
                                                controller: nameController,
                                                decoration: InputDecoration(
                                                  labelText: "Name",
                                                  filled: true,
                                                  fillColor: theme
                                                      .colorScheme
                                                      .surfaceVariant,
                                                ),
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 12),

                                              // Color picker
                                              const Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text("Color"),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                height: isMobileView ? 230 : 100,
                                                child: GridView.count(
                                                  crossAxisCount: isMobileView ? 5 : 10,
                                                  crossAxisSpacing: 8,
                                                  mainAxisSpacing: 8,
                                                  children: kCategoryColors.map((
                                                    c,
                                                  ) {
                                                    final isSelected =
                                                        c == selectedColor;
                                                    return GestureDetector(
                                                      onTap: () => setState(
                                                        () => selectedColor = c,
                                                      ),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: c,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: isSelected
                                                              ? Border.all(
                                                                  color: theme
                                                                      .colorScheme
                                                                      .onSurface,
                                                                  width: 3,
                                                                )
                                                              : null,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx2, null),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.colorScheme.primary,
                                              foregroundColor:
                                                  theme.colorScheme.onPrimary,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx2, {
                                                  "name": nameController.text
                                                      .trim(),
                                                  "color": selectedColor,
                                                }),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );

                                // Apply changes
                                if (result != null &&
                                    (result["name"] as String).isNotEmpty) {
                                  notifier.editCategory(
                                    latestCategory.id,
                                    name: result["name"],
                                    color: result["color"],
                                  );
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
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).baseContent,
                              ),
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
                            children: latestCategory.products
                                .where((p) => !p.isDeleted)
                                .map((p) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardsColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Theme.of(context).borderColor),
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
                                            color: Theme.of(context).error,
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
    final isMobileView = isMobile(context);

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
                    height: isMobileView ? 230 : 100,
                                                child: GridView.count(
                                                  crossAxisCount: isMobileView ? 5 : 10,
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
                  _TypeToggle(
                    selected: selectedType,
                    onChanged: (t) => setState(() => selectedType = t),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text("Cancel"),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).baseContent,
                ),
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

/// Expense/Income segmented toggle — replaces a plain DropdownButton with
/// something that matches the rest of the app's pill-styled controls
/// (e.g. the Expense/Income tabs on the categories page itself).
class _TypeToggle extends StatelessWidget {
  final CategoryType selected;
  final ValueChanged<CategoryType> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: _segment(theme, 'Expense', CategoryType.expense)),
        const SizedBox(width: 8),
        Expanded(child: _segment(theme, 'Income', CategoryType.income)),
      ],
    );
  }

  Widget _segment(ThemeData theme, String label, CategoryType type) {
    final active = selected == type;
    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? theme.ink : Colors.transparent,
          border: Border.all(color: active ? Colors.transparent : theme.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.sans(13, weight: FontWeight.w600,
              color: active ? theme.surface : theme.ink2),
        ),
      ),
    );
  }
}
