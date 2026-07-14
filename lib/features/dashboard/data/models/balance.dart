import '../../../../core/utils/money.dart';

class Balance {
  final String id; // Firestore doc ID
  final String userId;

  /// Source of truth, in millimes. See `core/utils/money.dart`.
  final int amountMillimes;

  /// Dinar-denominated view, for existing call sites.
  double get amount => millimesToDinars(amountMillimes);

  Balance({
    required this.id,
    required this.userId,
    double amount = 0.0,
  }) : amountMillimes = dinarsToMillimes(amount);

  Balance.fromMillimes({
    required this.id,
    required this.userId,
    this.amountMillimes = 0,
  });

  Balance copyWith({
    String? id,
    String? userId,
    double? amount,
  }) {
    return Balance.fromMillimes(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amountMillimes: amount != null ? dinarsToMillimes(amount) : amountMillimes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amountMillimes': amountMillimes,
    };
  }

  factory Balance.fromJson(Map<String, dynamic> json, {required String id}) {
    int parsedMillimes = 0;
    final dynamic millimesRaw = json['amountMillimes'];
    if (millimesRaw is int) {
      parsedMillimes = millimesRaw;
    } else if (millimesRaw is double) {
      parsedMillimes = millimesRaw.round();
    } else {
      // Legacy doc written before this refactor: only `amount` (double) exists.
      final dynamic legacyAmount = json['amount'];
      double legacyDouble = 0.0;
      if (legacyAmount is int) legacyDouble = legacyAmount.toDouble();
      if (legacyAmount is double) legacyDouble = legacyAmount;
      if (legacyAmount is String) legacyDouble = double.tryParse(legacyAmount) ?? 0.0;
      parsedMillimes = dinarsToMillimes(legacyDouble);
    }

    return Balance.fromMillimes(
      id: id,
      userId: json['userId']?.toString() ?? '',
      amountMillimes: parsedMillimes,
    );
  }

  @override
  String toString() => 'Balance(id: $id, userId: $userId, amountMillimes: $amountMillimes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Balance && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
