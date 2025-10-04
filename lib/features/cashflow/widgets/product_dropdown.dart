import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';

class ProductDropdown extends StatelessWidget {
  final String? categoryId;
  final String? selectedProduct;
  final ValueChanged<String?> onChanged;

  const ProductDropdown({super.key, this.categoryId, this.selectedProduct, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categoryNotifier = Provider.of<CategoryNotifier>(context);
    List<String> products = [];

    if (categoryId != null) {
      final category = categoryNotifier.getCategoryById(categoryId!);
      if (category != null) {
        products = category.products.where((p) => !p.isDeleted).map((p) => p.name).toList();
      }
    }

    return DropdownButtonFormField<String>(
      value: selectedProduct,
      decoration: const InputDecoration(labelText: 'Product'),
      items: products.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
      onChanged: onChanged,
    );
  }
}
