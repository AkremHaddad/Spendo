import 'package:cloud_firestore/cloud_firestore.dart';

class Cashflow {
  String id;
  String categoryId;
  String? productId;
  double amount;
  DateTime date;
  String userId;
  bool isDeleted;

  Cashflow({
    required this.id,
    required this.categoryId,
    this.productId,
    required this.amount,
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
    return Cashflow(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      productId: productId ?? this.productId,
      amount: amount ?? this.amount,
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
      'amount': amount,
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

    final dynamic amountRaw = json['amount'];
    double parsedAmount = 0;
    if (amountRaw is int) parsedAmount = amountRaw.toDouble();
    if (amountRaw is double) parsedAmount = amountRaw;
    if (amountRaw is String) parsedAmount = double.tryParse(amountRaw) ?? 0;

    final dynamic isDeletedRaw = json['isDeleted'];
    bool isDeleted = false;
    if (isDeletedRaw is bool) {
      isDeleted = isDeletedRaw;
    } else if (isDeletedRaw is int) {
      isDeleted = isDeletedRaw != 0;
    } else if (isDeletedRaw is String) {
      isDeleted = (isDeletedRaw.toLowerCase() == 'true');
    }

    return Cashflow(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      productId: json['productId']?.toString(),
      amount: parsedAmount,
      date: parsedDate,
      userId: json['userId']?.toString() ?? '',
      isDeleted: isDeleted,
    );
  }

  @override
  String toString() {
    return 'Cashflow(id: $id, categoryId: $categoryId, productId: $productId, amount: $amount, date: $date, userId: $userId, isDeleted: $isDeleted)';
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
  bool get isIncome => amount > 0;

  /// Returns true if this cashflow is expense
  bool get isExpense => amount < 0;
}
