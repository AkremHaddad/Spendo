// lib/notifiers/category_notifier.dart
import 'package:flutter/material.dart';
import '../data/models/category.dart';

class CategoryNotifier extends ChangeNotifier {
  final List<Category> _categories = [];

  // PUBLIC: only non-deleted categories
  List<Category> get categories => _categories.where((c) => !c.isDeleted).toList();

  // Get by id (nullable)
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id && !c.isDeleted);
    } catch (_) {
      return null;
    }
  }

  // Add category and return new id
  String addCategory(String name, Color color, CategoryType type) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final cat = Category(id: newId, name: name.trim(), color: color, type: type);
    _categories.add(cat);
    notifyListeners();
    return newId;
  }

  // Soft-delete category; returns true if success
  bool softDeleteCategory(String id) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    _categories[index].isDeleted = true;
    notifyListeners();
    return true;
  }

  // Edit category; returns true if success
  bool editCategory(String id, {String? name, Color? color}) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    final cat = _categories[index];
    if (name != null) cat.name = name.trim();
    if (color != null) cat.color = color;
    notifyListeners();
    return true;
  }

  // Add product to category (validates input). Returns product id if success, null otherwise.
  String? addProduct(String categoryId, String productName) {
    final catIndex = _categories.indexWhere((c) => c.id == categoryId && !c.isDeleted);
    if (catIndex == -1) {
      // category not found
      debugPrint('CategoryNotifier.addProduct: category not found for id=$categoryId');
      return null;
    }

    final trimmed = productName.trim();
    if (trimmed.isEmpty) {
      debugPrint('CategoryNotifier.addProduct: productName is empty');
      return null;
    }

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
    );

    _categories[catIndex].products.add(newProduct);
    notifyListeners();
    return newProduct.id;
  }

  // Soft-delete a product
  bool softDeleteProduct(String categoryId, String productId) {
    final cat = _categories.firstWhere(
      (c) => c.id == categoryId && !c.isDeleted,
      orElse: () => Category(
        id: '',
        name: '',
        color: const Color(0xFFFFFFFF),
        type: CategoryType.expense,
      ),
    );
    if (cat.id == '') return false;

    final pIndex = cat.products.indexWhere((p) => p.id == productId);
    if (pIndex == -1) return false;
    cat.products[pIndex].isDeleted = true;
    notifyListeners();
    return true;
  }

  // Edit product name
  bool editProduct(String categoryId, String productId, String newName) {
    final cat = _categories.firstWhere((c) => c.id == categoryId && !c.isDeleted,
        orElse: () => Category(
              id: '',
              name: '',
              color: const Color(0xFFFFFFFF),
              type: CategoryType.expense,
            ));
    if (cat.id == '') return false;

    final pIndex = cat.products.indexWhere((p) => p.id == productId && !p.isDeleted);
    if (pIndex == -1) return false;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    cat.products[pIndex].name = trimmed;
    notifyListeners();
    return true;
  }

  // helper to load categories from a map (e.g. from Firestore)
  void setCategoriesFromJsonList(List<Map<String, dynamic>> list) {
    _categories.clear();
    for (final m in list) {
      try {
        _categories.add(Category.fromJson(m));
      } catch (e, st) {
        debugPrint('Failed to parse category from json: $e\n$st');
      }
    }
    notifyListeners();
  }

  // Clear all categories (for testing)
  void clearAll() {
    _categories.clear();
    notifyListeners();
  }
}
