import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';

class CategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categoryNotifier = context.watch<CategoryNotifier>();
    final categories = categoryNotifier.categories;

    // Remove duplicate IDs just in case
    final uniqueCategories = {
      for (var c in categories) c.id: c,
    }.values.toList();

    // Make sure the current selectedCategory actually exists
    final validSelectedCategory = uniqueCategories.any((c) => c.id == selectedCategory)
        ? selectedCategory
        : null;

    return DropdownButtonFormField<String>(
      value: validSelectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: uniqueCategories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Select a category' : null,
    );
  }
}
