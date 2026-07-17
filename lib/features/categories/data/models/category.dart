// lib/data/models/category.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/money.dart';
import '../../category_style_options.dart';

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
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
  CategoryType type;
  List<Product> products;
  bool isDeleted;
  String userId;

  /// Key into [kCategoryColorOptions] — see category_style_options.dart.
  /// Resolved to an actual [Color] via [colorForCategoryKey], which picks
  /// the light- or dark-theme variant, so the same stored key adapts to
  /// whichever theme is active instead of being a single fixed color.
  String colorKey;

  /// Key into [kCategoryIcons] — see category_style_options.dart.
  String icon;

  /// Monthly budget target for this category, in millimes (see
  /// core/utils/money.dart). Null = no goal set for this category yet.
  int? monthlyGoalMillimes;

  /// Dinar-denominated view of [monthlyGoalMillimes], for call sites that
  /// just want a plain number (progress bars, form fields).
  double? get monthlyGoal => monthlyGoalMillimes == null ? null : millimesToDinars(monthlyGoalMillimes!);

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.userId,
    String? colorKey,
    List<Product>? products,
    this.isDeleted = false,
    String? icon,
    this.monthlyGoalMillimes,
  }) : products = products ?? [],
       colorKey = colorKey ?? kDefaultCategoryColorKey,
       icon = icon ?? suggestCategoryIconKey(name);

  Category copyWith({
    String? id,
    String? name,
    String? colorKey,
    CategoryType? type,
    List<Product>? products,
    bool? isDeleted,
    String? userId,
    String? icon,
    int? monthlyGoalMillimes,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      products: products ?? List<Product>.from(this.products),
      isDeleted: isDeleted ?? this.isDeleted,
      icon: icon ?? this.icon,
      monthlyGoalMillimes: monthlyGoalMillimes ?? this.monthlyGoalMillimes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorKey': colorKey,
        'type': type.toString().split('.').last,
        'products': products.map((p) => p.toJson()).toList(),
        'isDeleted': isDeleted,
        'userId': userId,
        'icon': icon,
        'monthlyGoalMillimes': monthlyGoalMillimes,
      };

  factory Category.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Category.fromJson received null');
    }

    // Prefer the new theme-aware color key; fall back to migrating a
    // legacy absolute 'color' int (from before categories supported
    // light/dark) to the nearest curated key.
    String colorKey;
    final dynamic colorKeyRaw = json['colorKey'];
    if (colorKeyRaw is String && colorKeyRaw.isNotEmpty) {
      colorKey = colorKeyRaw;
    } else {
      final dynamic legacyColorRaw = json['color'];
      int legacyColorValue = 0xFF2D6948;
      if (legacyColorRaw is int) {
        legacyColorValue = legacyColorRaw;
      } else if (legacyColorRaw is String) {
        legacyColorValue = int.tryParse(legacyColorRaw) ?? legacyColorValue;
      }
      colorKey = nearestCategoryColorKey(Color(legacyColorValue));
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

    final dynamic goalRaw = json['monthlyGoalMillimes'];
    int? monthlyGoalMillimes;
    if (goalRaw is int) {
      monthlyGoalMillimes = goalRaw;
    } else if (goalRaw is double) {
      monthlyGoalMillimes = goalRaw.round();
    }

    final name = json['name']?.toString() ?? '';
    return Category(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      colorKey: colorKey,
      type: type,
      userId: json['userId']?.toString() ?? '',
      products: products,
      isDeleted: isDeleted,
      icon: json['icon']?.toString() ?? suggestCategoryIconKey(name),
      monthlyGoalMillimes: monthlyGoalMillimes,
    );
  }

  // helper to get visible (non-deleted) products
  List<Product> get visibleProducts => products.where((p) => !p.isDeleted).toList();

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, userId: $userId, products: ${products.length}, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id && userId == other.userId;

  @override
  int get hashCode => Object.hash(id, userId);
}