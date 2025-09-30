import 'package:flutter/material.dart';
import '../data/models/category.dart';
import 'category_detail_dialog.dart';
import '../../../core/theme/theme.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Open the category detail dialog
          CategoryDetailDialog.showCategoryDetailDialog(context, category);
        },
        borderRadius: BorderRadius.circular(8),
        splashColor: theme.colorScheme.primary.withOpacity(0.2),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).base100,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black12
                    : Colors.black45, // darker shadow in dark mode
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : Colors.grey.shade800,
                    width: 1,
                  ),
                ),
              ),
              // Category name
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, color: theme.iconTheme.color),
            ],
          ),
        ),
      ),
    );
  }
}
