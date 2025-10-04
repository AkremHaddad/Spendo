import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';

class CategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({super.key, this.selectedCategory, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categoryNotifier = Provider.of<CategoryNotifier>(context);
    final categories = categoryNotifier.categories;

    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: const InputDecoration(labelText: 'Category'),
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Select a category' : null,
    );
  }
}
