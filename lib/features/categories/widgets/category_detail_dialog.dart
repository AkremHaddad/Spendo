import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../data/models/category.dart';
import '../category_style_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';

class CategoryDetailDialog {
  /// Show category detail dialog
  static void showCategoryDetailDialog(BuildContext context, Category category) {
    final productInputController = TextEditingController();

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
            final tintInk = colorForCategoryKey(latestCategory.colorKey, theme.brightness);
            final tintBg = tintInk.withOpacity(0.12);

            void addProduct() {
              final name = productInputController.text.trim();
              if (name.isEmpty) return;
              notifier.addProduct(latestCategory.id, name);
              productInputController.clear();
            }

            Future<void> editProductDialog(String productId, String currentName) async {
              final controller = TextEditingController(text: currentName);
              final newName = await showDialog<String>(
                context: ctx2,
                builder: (_) => AlertDialog(
                  title: Text('Edit product', style: theme.serif(20)),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onSubmitted: (v) => Navigator.pop(ctx2, v.trim()),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx2, null), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx2, controller.text.trim()), child: const Text('Save')),
                  ],
                ),
              );
              if (newName != null && newName.isNotEmpty) {
                notifier.editProduct(latestCategory.id, productId, newName);
              }
            }

            Future<bool> confirmDialog({
              required String title,
              required String body,
              required String confirmLabel,
            }) async {
              final result = await showDialog<bool>(
                context: ctx2,
                builder: (confirmCtx) => AlertDialog(
                  title: Text(title, style: theme.serif(20)),
                  content: Text(body, style: theme.sans(14, color: theme.ink2)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.tintCoralInk,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(confirmCtx, true),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              );
              return result ?? false;
            }

            Future<void> confirmDeleteProduct(String productId) async {
              if (await confirmDialog(
                title: 'Delete product',
                body: 'Are you sure you want to delete this product?',
                confirmLabel: 'Delete',
              )) {
                notifier.softDeleteProduct(latestCategory.id, productId);
              }
            }

            Future<void> confirmDeleteCategory() async {
              if (await confirmDialog(
                title: 'Delete category',
                body: "Are you sure you want to delete this category? This can't be undone.",
                confirmLabel: 'Delete',
              )) {
                final success = await notifier.softDeleteCategory(latestCategory.id);
                if (success) {
                  final nav = Navigator.of(ctx2);
                  if (nav.mounted && nav.canPop()) nav.pop();
                } else if (ScaffoldMessenger.maybeOf(ctx2) != null) {
                  ScaffoldMessenger.of(ctx2).showSnackBar(
                    const SnackBar(content: Text('Failed to delete category')),
                  );
                }
              }
            }

            void openEditCategoryDialog() {
              _showCategoryFormDialog(
                ctx2,
                title: 'Edit category',
                initialName: latestCategory.name,
                initialColorKey: latestCategory.colorKey,
                initialIcon: latestCategory.icon,
                initialType: latestCategory.type,
                initialGoal: latestCategory.monthlyGoal,
                isEditing: true,
                onSubmit: (name, colorKey, icon, type, goal) {
                  notifier.editCategory(
                    latestCategory.id,
                    name: name,
                    colorKey: colorKey,
                    icon: icon,
                    monthlyGoal: goal,
                    clearMonthlyGoal: goal == null,
                  );
                },
              );
            }

            final products = latestCategory.visibleProducts;

            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile(context) ? MediaQuery.of(context).size.width * 0.92 : 480,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: tintBg, borderRadius: BorderRadius.circular(14)),
                            child: Icon(iconForCategoryKey(latestCategory.icon), color: tintInk, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(latestCategory.name,
                                    style: theme.serif(20), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (latestCategory.monthlyGoal != null)
                                  Text(
                                    'Goal: \$${latestCategory.monthlyGoal!.toStringAsFixed(0)}/mo',
                                    style: theme.sans(12.5, color: theme.ink2),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: theme.ink2, size: 20),
                            onPressed: openEditCategoryDialog,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: theme.tintCoralInk, size: 20),
                            onPressed: confirmDeleteCategory,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.border),

                    // Products list
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Products', style: theme.sans(12.5, weight: FontWeight.w700, color: theme.ink2)),
                            const SizedBox(height: 10),
                            if (products.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text('No products yet', style: theme.sans(13.5, color: theme.ink2)),
                              )
                            else
                              ...products.map((p) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: theme.surface2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(p.name,
                                              style: theme.sans(13.5, weight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        GestureDetector(
                                          onTap: () => editProductDialog(p.id, p.name),
                                          child: Icon(Icons.edit_outlined, size: 17, color: theme.ink2),
                                        ),
                                        const SizedBox(width: 14),
                                        GestureDetector(
                                          onTap: () => confirmDeleteProduct(p.id),
                                          child: Icon(Icons.delete_outline_rounded, size: 17, color: theme.tintCoralInk),
                                        ),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ),

                    // Add product row
                    Divider(height: 1, color: theme.border),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: productInputController,
                              decoration: const InputDecoration(labelText: 'New product'),
                              onSubmitted: (_) => addProduct(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(onPressed: addProduct, child: const Text('Add')),
                        ],
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

  /// Show dialog to add a new category. [initialType] should reflect
  /// whichever Expense/Income tab the user was on when they tapped "New
  /// category"/"New income" — it was previously hardcoded to expense, so
  /// tapping "New income" silently opened the form defaulted to Expense.
  static void showAddCategoryDialog(BuildContext context, {CategoryType initialType = CategoryType.expense}) {
    _showCategoryFormDialog(
      context,
      title: initialType == CategoryType.expense ? 'New category' : 'New income',
      initialName: '',
      initialColorKey: kDefaultCategoryColorKey,
      initialIcon: kDefaultCategoryIconKey,
      initialType: initialType,
      initialGoal: null,
      isEditing: false,
      onSubmit: (name, colorKey, icon, type, goal) {
        context.read<CategoryNotifier>().addCategory(name, colorKey, type, icon: icon, monthlyGoal: goal);
      },
    );
  }
}

/// Shared add/edit form — name, icon, color, type (locked when editing), and
/// an optional monthly goal. Used by both [CategoryDetailDialog.showAddCategoryDialog]
/// and the edit action inside [CategoryDetailDialog.showCategoryDetailDialog].
void _showCategoryFormDialog(
  BuildContext context, {
  required String title,
  required String initialName,
  required String initialColorKey,
  required String initialIcon,
  required CategoryType initialType,
  required double? initialGoal,
  required bool isEditing,
  required void Function(String name, String colorKey, String icon, CategoryType type, double? goal) onSubmit,
}) {
  final nameController = TextEditingController(text: initialName);
  final goalController = TextEditingController(
    text: initialGoal == null ? '' : _formatGoalForInput(initialGoal),
  );
  String selectedColorKey = initialColorKey;
  String selectedIcon = initialIcon;
  CategoryType selectedType = initialType;
  // While adding, typing a name auto-picks a matching icon until the user
  // manually taps one; while editing an existing category we respect
  // whatever icon is already set unless they explicitly change it.
  bool iconManuallyChosen = isEditing;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setState) {
        final theme = Theme.of(ctx2);
        final mobile = isMobile(ctx2);

        return AlertDialog(
          title: Text(title, style: theme.serif(22)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (value) {
                      if (!iconManuallyChosen) {
                        setState(() => selectedIcon = suggestCategoryIconKey(value));
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Icon', style: theme.sans(12.5, weight: FontWeight.w700, color: theme.ink2)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: mobile ? 168 : 128,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kCategoryIcons.entries.map((entry) {
                          final isSelected = entry.key == selectedIcon;
                          final selectedColor = colorForCategoryKey(selectedColorKey, theme.brightness);
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedIcon = entry.key;
                              iconManuallyChosen = true;
                            }),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? selectedColor.withOpacity(0.15) : theme.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: selectedColor, width: 2) : null,
                              ),
                              child: Icon(entry.value, size: 20, color: isSelected ? selectedColor : theme.ink2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Color', style: theme.sans(12.5, weight: FontWeight.w700, color: theme.ink2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kCategoryColorOptions.map((option) {
                      final isSelected = option.key == selectedColorKey;
                      final swatch = colorForCategoryKey(option.key, theme.brightness);
                      return GestureDetector(
                        onTap: () => setState(() => selectedColorKey = option.key),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: theme.ink, width: 3) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  if (!isEditing) ...[
                    _TypeToggle(selected: selectedType, onChanged: (t) => setState(() => selectedType = t)),
                    const SizedBox(height: 18),
                  ],
                  TextField(
                    controller: goalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monthly goal (optional)',
                      hintText: 'e.g. 150',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final goal = double.tryParse(goalController.text.trim());
                onSubmit(name, selectedColorKey, selectedIcon, selectedType, goal);
                Navigator.pop(ctx2);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

String _formatGoalForInput(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

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
