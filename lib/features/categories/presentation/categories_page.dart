import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../data/models/category.dart';
import '../widgets/category_card.dart';
import '../widgets/category_detail_dialog.dart';
import '../../../core/theme/theme.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    // Load categories from Firestore on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryNotifier>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context
        .watch<CategoryNotifier>()
        .categories
        .where((c) => !c.isDeleted)
        .toList();
    final expenses = categories
        .where((c) => c.type == CategoryType.expense)
        .toList();
    final income = categories
        .where((c) => c.type == CategoryType.income)
        .toList();

    return Scaffold(
      backgroundColor: theme.base300,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top custom app bar container (no padding)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.baseContent,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        CategoryDetailDialog.showAddCategoryDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.primaryContent,
                    ),
                    child: const Text("Add"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Body content (with padding)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expenses:",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primarytext,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    Text(
                      "No expense categories yet.",
                      style: TextStyle(color: theme.baseContent),
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: expenses
                        .map(
                          (c) => SizedBox(
                            width: 300,
                            child: CategoryCard(category: c),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Income:",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primarytext,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (income.isEmpty)
                    Text(
                      "No income categories yet.",
                      style: TextStyle(color: theme.baseContent),
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: income
                        .map(
                          (c) => SizedBox(
                            width: 300,
                            child: CategoryCard(category: c),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
