import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/category.dart';

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class CategoryNotifier extends ChangeNotifier {
  final List<Category> _categories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  StreamSubscription<QuerySnapshot>? _subscription;

  CategoryNotifier({required this.userId}) {
    loadCategories();
  }

  // ---------------- Public getters ----------------
  List<Category> get categories => _categories.where((c) => !c.isDeleted).toList();

  List<Category> get expenseCategories =>
      _categories.where((c) => !c.isDeleted && c.type == CategoryType.expense).toList();

  List<Category> get incomeCategories =>
      _categories.where((c) => !c.isDeleted && c.type == CategoryType.income).toList();

  Category? getCategoryById(String id) =>
      _categories.where((c) => c.id == id && !c.isDeleted).firstOrNull;

  // ---------------- Firestore real-time listener ----------------
  void loadCategories() {
    if (userId.isEmpty) return;
    _subscription?.cancel();

    _subscription = _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _categories.clear();
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          _categories.add(Category.fromJson(data));
        } catch (e, st) {
          debugPrint('Failed to parse category ${doc.id}: $e\n$st');
        }
      }
      notifyListeners();
    });
  }

  // ---------------- Category CRUD ----------------
  Future<String> addCategory(String name, Color color, CategoryType type) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final cat = Category(
      id: newId,
      name: name.trim(),
      color: color,
      type: type,
      userId: userId,
      products: [],
    );

    _categories.add(cat); // optimistic update
    notifyListeners();

    await _firestore.collection('categories').doc(newId).set(cat.toJson());
    return newId;
  }

  Future<bool> editCategory(String id, {String? name, Color? color}) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final cat = _categories[index];
    final updatedCat = cat.copyWith(
      name: name ?? cat.name,
      color: color ?? cat.color,
    );

    _categories[index] = updatedCat; // optimistic
    notifyListeners();

    await _firestore.collection('categories').doc(id).update(updatedCat.toJson());
    return true;
  }

  Future<bool> softDeleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    _categories[index].isDeleted = true; // optimistic
    notifyListeners();

    await _firestore.collection('categories').doc(id).update({'isDeleted': true});
    return true;
  }

  // ---------------- Products ----------------
  Future<String?> addProduct(String categoryId, String productName) async {
    final catIndex =
        _categories.indexWhere((c) => c.id == categoryId && !c.isDeleted);
    if (catIndex == -1) return null;

    final trimmed = productName.trim();
    if (trimmed.isEmpty) return null;

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      isDeleted: false,
    );

    _categories[catIndex].products.add(newProduct);
    notifyListeners();

    await _firestore.collection('categories').doc(categoryId).update({
      'products': _categories[catIndex].products.map((p) => p.toJson()).toList(),
    });

    return newProduct.id;
  }

  Future<bool> editProduct(String categoryId, String productId, String newName) async {
    final catIndex =
        _categories.indexWhere((c) => c.id == categoryId && !c.isDeleted);
    if (catIndex == -1) return false;

    final pIndex = _categories[catIndex]
        .products
        .indexWhere((p) => p.id == productId && !p.isDeleted);
    if (pIndex == -1) return false;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    _categories[catIndex].products[pIndex].name = trimmed; // optimistic
    notifyListeners();

    await _firestore.collection('categories').doc(categoryId).update({
      'products': _categories[catIndex].products.map((p) => p.toJson()).toList(),
    });

    return true;
  }

  Future<bool> softDeleteProduct(String categoryId, String productId) async {
    final catIndex =
        _categories.indexWhere((c) => c.id == categoryId && !c.isDeleted);
    if (catIndex == -1) return false;

    final pIndex =
        _categories[catIndex].products.indexWhere((p) => p.id == productId);
    if (pIndex == -1) return false;

    _categories[catIndex].products[pIndex].isDeleted = true; // optimistic
    notifyListeners();

    await _firestore.collection('categories').doc(categoryId).update({
      'products': _categories[catIndex].products.map((p) => p.toJson()).toList(),
    });

    return true;
  }

  // ---------------- Misc ----------------
  void setCategoriesFromJsonList(List<Map<String, dynamic>> list) {
    _categories.clear();
    for (final m in list) {
      try {
        final cat = Category.fromJson(m);
        if (cat.userId == userId) _categories.add(cat);
      } catch (e, st) {
        debugPrint('Failed to parse category from JSON: $e\n$st');
      }
    }
    notifyListeners();
  }

  void clearAll() {
    _categories.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
