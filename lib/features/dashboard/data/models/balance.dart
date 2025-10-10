class Balance {
  final String id; // Firestore doc ID
  final String userId;
  double amount;

  Balance({
    required this.id,
    required this.userId,
    this.amount = 0.0,
  });

  Balance copyWith({
    String? id,
    String? userId,
    double? amount,
  }) {
    return Balance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
    };
  }

  factory Balance.fromJson(Map<String, dynamic> json, {required String id}) {
    final dynamic amountRaw = json['amount'];
    double parsedAmount = 0.0;
    if (amountRaw is int) parsedAmount = amountRaw.toDouble();
    if (amountRaw is double) parsedAmount = amountRaw;
    if (amountRaw is String) parsedAmount = double.tryParse(amountRaw) ?? 0.0;

    return Balance(
      id: id,
      userId: json['userId']?.toString() ?? '',
      amount: parsedAmount,
    );
  }

  @override
  String toString() => 'Balance(id: $id, userId: $userId, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Balance && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
