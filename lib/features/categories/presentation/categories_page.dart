import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../data/models/category.dart';
import '../widgets/category_card.dart';
import '../widgets/category_detail_dialog.dart';
import '../../../core/theme/theme.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context
        .watch<CategoryNotifier>()
        .categories
        .where((c) => !c.isDeleted)
        .toList();
    final expenses =
        categories.where((c) => c.type == CategoryType.expense).toList();
    final income =
        categories.where((c) => c.type == CategoryType.income).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).base300, // adapts to light/dark
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).baseContent,
                    ),
                  ),
                 ElevatedButton(
                  onPressed: () => CategoryDetailDialog.showAddCategoryDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).primaryContent,
                  ),
                  child: const Text("Add"),
                ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Expenses:",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                Text(
                  "No expense categories yet.",
                  style: TextStyle(color: Theme.of(context).baseContent),
                ),
              Wrap(
                spacing: 12, // horizontal space between cards
                runSpacing: 12, // vertical space between rows
                children: expenses.map((c) {
                  return SizedBox(
                    width: 300, // fixed width
                    child: CategoryCard(category: c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Text(
                "Income:",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (income.isEmpty)
                Text(
                  "No income categories yet.",
                  style: TextStyle(color: Theme.of(context).baseContent),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: income.map((c) {
                  return SizedBox(width: 300, child: CategoryCard(category: c));
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}