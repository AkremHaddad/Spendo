import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/cashflow.dart';

class CashflowNotifier extends ChangeNotifier {
  DateTime? _lastSelectedDate;
DateTime? get lastSelectedDate => _lastSelectedDate;

void setLastSelectedDate(DateTime date) {
  _lastSelectedDate = date;
}

  final String userId;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Cashflow> _cashflows = [];
  List<Cashflow> get cashflows => _cashflows;

  CashflowNotifier({required this.userId});

  /// =====================
  /// Load cashflows for a specific date
  Future<void> loadCashflowsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await firestore
          .collection('cashflows')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .orderBy('date', descending: true)
          .get();

      _cashflows = snapshot.docs
          .map((doc) => Cashflow.fromJson(doc.data() as Map<String, dynamic>)
              .copyWith(id: doc.id))
          .toList();
      notifyListeners();
    } catch (e, st) {
      debugPrint('Error loading cashflows for date $date: $e\n$st');
    }
  }

  /// =====================
  /// Add cashflow + atomically update balance in balances/{userId}
  Future<void> addCashflow(Cashflow cashflow) async {
    try {
      final cashflowRef = firestore.collection('cashflows').doc(); // new id
      final balanceRef = firestore.collection('balances').doc(userId); // single doc per user

      // prepare amount delta depending on income/expense:
      // assume cashflow.amount is positive for both; we will add for income, subtract for expense
      final double delta = cashflow.isIncome ? cashflow.amount : -cashflow.amount.abs();

      final result = await firestore.runTransaction((transaction) async {
        final balanceSnap = await transaction.get(balanceRef);
        double currentBalance = 0.0;

        if (balanceSnap.exists && balanceSnap.data() != null) {
          final amt = balanceSnap.data()!['amount'];
          currentBalance = (amt is int) ? amt.toDouble() : (amt as double);
        } else {
          // If missing, initialize
          transaction.set(balanceRef, {'userId': userId, 'amount': 0.0});
          currentBalance = 0.0;
        }

        final newBalance = currentBalance + delta;

        // set cashflow doc (include userId and timestamps as needed)
        final newCashflow = cashflow.copyWith(id: cashflowRef.id);

        transaction.set(cashflowRef, newCashflow.toJson());
        transaction.update(balanceRef, {'amount': newBalance});

        return newBalance;
      });

      // update local cache and notify - dashboard will also pick up update via its listener
      final inserted = cashflow.copyWith(id: cashflowRef.id);
      if (_cashflows.isNotEmpty &&
          cashflow.date.year == _cashflows[0].date.year &&
          cashflow.date.month == _cashflows[0].date.month &&
          cashflow.date.day == _cashflows[0].date.day) {
        _cashflows.insert(0, inserted);
      }
      notifyListeners();

      // Note: we don't keep a separate balance variable here; DashboardNotifier listens to balances/{userId}.
    } catch (e, st) {
      debugPrint('Error adding cashflow and updating balance: $e\n$st');
      rethrow;
    }
  }

  /// Soft delete cashflow and reverse its effect
  Future<void> deleteCashflow(String id) async {
    try {
      final cashflowRef = firestore.collection('cashflows').doc(id);
      final balanceRef = firestore.collection('balances').doc(userId);

      final result = await firestore.runTransaction((transaction) async {
        final cfSnap = await transaction.get(cashflowRef);

        if (!cfSnap.exists || cfSnap.data() == null) {
          throw Exception('Cashflow missing');
        }

        // read amount from cashflow
        final data = cfSnap.data()! as Map<String, dynamic>;
        final amtRaw = data['amount'];
        final bool isIncome = data['isIncome'] == true;
        final double cfAmount = (amtRaw is int) ? amtRaw.toDouble() : (amtRaw as double);

        // compute delta to subtract (reverse)
        final double delta = isIncome ? -cfAmount : cfAmount.abs();

        final balanceSnap = await transaction.get(balanceRef);
        if (!balanceSnap.exists || balanceSnap.data() == null) {
          throw Exception('Balance missing');
        }

        final balRaw = balanceSnap.data()!['amount'];
        double currentBalance = (balRaw is int) ? balRaw.toDouble() : (balRaw as double);

        final newBalance = currentBalance + delta;

        transaction.update(balanceRef, {'amount': newBalance});
        transaction.update(cashflowRef, {'isDeleted': true});

        return newBalance;
      });

      // update local cache & notify
      _cashflows.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e, st) {
      debugPrint('Error deleting cashflow and updating balance: $e\n$st');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}