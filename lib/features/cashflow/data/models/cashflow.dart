import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/money.dart';

class Cashflow {
  String id;
  String categoryId;
  String? productId;

  /// Source of truth for the amount, in millimes (1 TND = 1000 millimes).
  /// See `core/utils/money.dart` for why this isn't a `double`.
  int amountMillimes;

  DateTime date;
  String userId;
  bool isDeleted;

  /// Dinar-denominated view of [amountMillimes], for call sites that just
  /// want a plain number (charts, existing widgets). Positive = income,
  /// negative = expense, same convention as before.
  double get amount => millimesToDinars(amountMillimes);

  Cashflow({
    required this.id,
    required this.categoryId,
    this.productId,
    required double amount,
    required this.date,
    required this.userId,
    this.isDeleted = false,
  }) : amountMillimes = dinarsToMillimes(amount);

  Cashflow.fromMillimes({
    required this.id,
    required this.categoryId,
    this.productId,
    required this.amountMillimes,
    required this.date,
    required this.userId,
    this.isDeleted = false,
  });

  Cashflow copyWith({
    String? id,
    String? categoryId,
    String? productId,
    double? amount,
    DateTime? date,
    String? userId,
    bool? isDeleted,
  }) {
    return Cashflow.fromMillimes(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      productId: productId ?? this.productId,
      amountMillimes: amount != null ? dinarsToMillimes(amount) : amountMillimes,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'productId': productId,
      'amountMillimes': amountMillimes,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'isDeleted': isDeleted,
    };
  }

  factory Cashflow.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Cashflow.fromJson received null');
    }

    // Handle date from Firestore Timestamp or String
    DateTime parsedDate = DateTime.now();
    final dynamic rawDate = json['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? parsedDate;
    }

    // Prefer the new integer-millimes field; fall back to the legacy
    // double `amount` field for documents written before this refactor.
    int parsedMillimes = 0;
    final dynamic millimesRaw = json['amountMillimes'];
    if (millimesRaw is int) {
      parsedMillimes = millimesRaw;
    } else if (millimesRaw is double) {
      parsedMillimes = millimesRaw.round();
    } else {
      final dynamic legacyAmount = json['amount'];
      double legacyDouble = 0;
      if (legacyAmount is int) legacyDouble = legacyAmount.toDouble();
      if (legacyAmount is double) legacyDouble = legacyAmount;
      if (legacyAmount is String) legacyDouble = double.tryParse(legacyAmount) ?? 0;
      parsedMillimes = dinarsToMillimes(legacyDouble);
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

    return Cashflow.fromMillimes(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      productId: json['productId']?.toString(),
      amountMillimes: parsedMillimes,
      date: parsedDate,
      userId: json['userId']?.toString() ?? '',
      isDeleted: isDeleted,
    );
  }

  @override
  String toString() {
    return 'Cashflow(id: $id, categoryId: $categoryId, productId: $productId, amountMillimes: $amountMillimes, date: $date, userId: $userId, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cashflow && runtimeType == other.runtimeType && id == other.id && userId == other.userId;

  @override
  int get hashCode => Object.hash(id, userId);
}

extension CashflowHelpers on Cashflow {
  /// Returns true if this cashflow is income
  bool get isIncome => amountMillimes > 0;

  /// Returns true if this cashflow is expense
  bool get isExpense => amountMillimes < 0;
}
