import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/category.dart';

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class CategoryNotifier extends ChangeNotifier {
  final List<Category> _categories = [];
  // Includes deleted categories (used for reports & charts)
  List<Category> get allCategories => List.unmodifiable(_categories);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  StreamSubscription<QuerySnapshot>? _subscription;

  // mounted guard for safe notify
  bool _isMounted = true;

  CategoryNotifier({required this.userId}) {
    loadCategories();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _isMounted = false;
    super.dispose();
  }

  void _safeNotify() {
    if (_isMounted) notifyListeners();
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
      // build a new list first (avoid modifying _categories while UI rebuilding)
      final loaded = <Category>[];
      for (var doc in snapshot.docs) {
        try {
          final raw = Map<String, dynamic>.from(doc.data());
          // ensure id exists
          if (raw['id'] == null || raw['id'].toString().isEmpty) {
            raw['id'] = doc.id;
          }
          final cat = Category.fromJson(raw);
          loaded.add(cat);
        } catch (e, st) {
          debugPrint('Failed to parse category ${doc.id}: $e\n$st');
        }
      }

      // atomically replace local list
      _categories
        ..clear()
        ..addAll(loaded);

      _safeNotify();
    }, onError: (e, st) {
      debugPrint('Category listener error: $e\n$st');
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

    // write to Firestore (no optimistic local mutation)
    await _firestore.collection('categories').doc(newId).set(cat.toJson());
    // snapshot listener will pick it up and update _categories
    return newId;
  }

  Future<bool> editCategory(String id, {String? name, Color? color}) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (color != null) updates['color'] = color.value;

    if (updates.isEmpty) return false;

    try {
      await _firestore.collection('categories').doc(id).update(updates);
      return true;
    } catch (e, st) {
      debugPrint('Failed to edit category $id: $e\n$st');
      return false;
    }
  }

  // IMPORTANT: write to Firestore first, then update local state after success
  Future<bool> softDeleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    try {
      await _firestore.collection('categories').doc(id).update({'isDeleted': true});

      // update local copy only after successful write (snapshot may already remove it,
      // but this keeps local data consistent and avoids race conditions)
      final localIndex = _categories.indexWhere((c) => c.id == id);
      if (localIndex != -1) {
        _categories[localIndex].isDeleted = true;
        _safeNotify();
      }
      return true;
    } catch (e, st) {
      debugPrint('Error soft-deleting category $id: $e\n$st');
      return false;
    }
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

    // fetch doc, append product and update server - safer than optimistic update
    final docRef = _firestore.collection('categories').doc(categoryId);
    final doc = await docRef.get();
    if (!doc.exists) return null;

    final raw = Map<String, dynamic>.from(doc.data()!);
    final rawProducts = raw['products'] is List ? List.from(raw['products']) : [];
    rawProducts.add(newProduct.toJson());
    await docRef.update({'products': rawProducts});

    // snapshot listener will update local list
    return newProduct.id;
  }

  Future<bool> editProduct(String categoryId, String productId, String newName) async {
    final docRef = _firestore.collection('categories').doc(categoryId);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final raw = Map<String, dynamic>.from(doc.data()!);
    final rawProducts = raw['products'] is List ? List.from(raw['products']) : [];
    var changed = false;
    final updated = rawProducts.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e);
      if (m['id'] == productId) {
        m['name'] = newName.trim();
        changed = true;
      }
      return m;
    }).toList();
    if (!changed) return false;

    try {
      await docRef.update({'products': updated});
      return true;
    } catch (e, st) {
      debugPrint('Failed to edit product $productId in $categoryId: $e\n$st');
      return false;
    }
  }

  Future<bool> softDeleteProduct(String categoryId, String productId) async {
    final docRef = _firestore.collection('categories').doc(categoryId);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final raw = Map<String, dynamic>.from(doc.data()!);
    final rawProducts = raw['products'] is List ? List.from(raw['products']) : [];
    var found = false;
    final updated = rawProducts.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e);
      if (m['id'] == productId) {
        m['isDeleted'] = true;
        found = true;
      }
      return m;
    }).toList();
    if (!found) return false;

    try {
      await docRef.update({'products': updated});
      return true;
    } catch (e, st) {
      debugPrint('Failed to soft-delete product $productId in $categoryId: $e\n$st');
      return false;
    }
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
    _safeNotify();
  }

  void clearAll() {
    _categories.clear();
    _safeNotify();
  }
}
