// lib/data/models/category.dart
import 'package:flutter/material.dart';

class Product {
  String id;
  String name;
  bool isDeleted;

  Product({
    required this.id,
    required this.name,
    this.isDeleted = false,
  });

  Product copyWith({String? id, String? name, bool? isDeleted}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isDeleted': isDeleted,
      };

  factory Product.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Product.fromJson received null');
    }
    final dynamic isDeletedRaw = json['isDeleted'];
    bool isDeleted = false;
    if (isDeletedRaw is bool) {
      isDeleted = isDeletedRaw;
    } else if (isDeletedRaw is int) {
      isDeleted = isDeletedRaw != 0;
    } else if (isDeletedRaw is String) {
      isDeleted = (isDeletedRaw.toLowerCase() == 'true');
    }

    return Product(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      isDeleted: isDeleted,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, isDeleted: $isDeleted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum CategoryType { expense, income }

class Category {
  String id;
  String name;
  Color color;
  CategoryType type;
  List<Product> products;
  bool isDeleted;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
    List<Product>? products,
    this.isDeleted = false,
  }) : products = products ?? [];

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    CategoryType? type,
    List<Product>? products,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      products: products ?? List<Product>.from(this.products),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        // store color as int so it's Firestore-friendly
        'color': color.value,
        'type': type.toString().split('.').last,
        'products': products.map((p) => p.toJson()).toList(),
        'isDeleted': isDeleted,
      };

  factory Category.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Category.fromJson received null');
    }

    // color stored as int (value) or maybe Map – handle common cases
    int colorValue = 0xFF2196F3; // fallback (blue)
    final dynamic colorRaw = json['color'];
    if (colorRaw is int) {
      colorValue = colorRaw;
    } else if (colorRaw is String) {
      colorValue = int.tryParse(colorRaw) ?? colorValue;
    }

    final String typeStr = (json['type']?.toString() ?? 'expense').toLowerCase();
    final CategoryType type = (typeStr == 'income') ? CategoryType.income : CategoryType.expense;

    final rawProducts = json['products'];
    List<Product> products = [];
    if (rawProducts is List) {
      products = rawProducts
          .where((e) => e != null)
          .map((e) {
            if (e is Product) return e;
            if (e is Map<String, dynamic>) return Product.fromJson(e);
            if (e is Map) return Product.fromJson(Map<String, dynamic>.from(e));
            return null;
          })
          .whereType<Product>()
          .toList();
    }

    final dynamic isDeletedRaw = json['isDeleted'];
    bool isDeleted = false;
    if (isDeletedRaw is bool) {
      isDeleted = isDeletedRaw;
    } else if (isDeletedRaw is int) {
      isDeleted = isDeletedRaw != 0;
    } else if (isDeletedRaw is String) {
      isDeleted = (isDeletedRaw.toLowerCase() == 'true');
    }

    return Category(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      color: Color(colorValue),
      type: type,
      products: products,
      isDeleted: isDeleted,
    );
  }

  // helper to get visible (non-deleted) products
  List<Product> get visibleProducts => products.where((p) => !p.isDeleted).toList();

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, products: ${products.length}, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
