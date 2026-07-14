import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/cashflow.dart';
import '../../../core/utils/money.dart';

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

  /// Reads a balance doc's amount as millimes, falling back to the legacy
  /// double `amount` field for docs written before the money refactor.
  int _balanceMillimesFrom(Map<String, dynamic> data) {
    final millimesRaw = data['amountMillimes'];
    if (millimesRaw is int) return millimesRaw;
    if (millimesRaw is double) return millimesRaw.round();
    final legacyAmount = data['amount'];
    final legacyDouble = (legacyAmount is int)
        ? legacyAmount.toDouble()
        : (legacyAmount is double ? legacyAmount : 0.0);
    return dinarsToMillimes(legacyDouble);
  }

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

      // Integer millimes delta: add for income, subtract for expense.
      // cashflow.amountMillimes already carries the sign (positive = income,
      // negative = expense — see AddTransactionForm), so this is just the
      // signed value itself; no float arithmetic involved.
      final int deltaMillimes = cashflow.amountMillimes;

      await firestore.runTransaction((transaction) async {
        final balanceSnap = await transaction.get(balanceRef);
        int currentMillimes = 0;

        if (balanceSnap.exists && balanceSnap.data() != null) {
          currentMillimes = _balanceMillimesFrom(balanceSnap.data()!);
        } else {
          transaction.set(balanceRef, {'userId': userId, 'amountMillimes': 0});
        }

        final newMillimes = currentMillimes + deltaMillimes;

        final newCashflow = cashflow.copyWith(id: cashflowRef.id);

        transaction.set(cashflowRef, newCashflow.toJson());
        transaction.update(balanceRef, {'amountMillimes': newMillimes});
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

      await firestore.runTransaction((transaction) async {
        final cfSnap = await transaction.get(cashflowRef);

        if (!cfSnap.exists || cfSnap.data() == null) {
          throw Exception('Cashflow missing');
        }

        final data = cfSnap.data()! as Map<String, dynamic>;
        // BUGFIX: this used to read a stored `isIncome` field that
        // `Cashflow.toJson()` never actually wrote, so it was always false —
        // every deleted cashflow (including income) was reversed as if it
        // were an expense, silently corrupting the balance. Income/expense
        // is encoded by the sign of the amount itself (see AddTransactionForm),
        // so derive it from that, the same convention the rest of the app uses.
        final int cfMillimes = _balanceMillimesFrom(data);

        final balanceSnap = await transaction.get(balanceRef);
        if (!balanceSnap.exists || balanceSnap.data() == null) {
          throw Exception('Balance missing');
        }

        final currentMillimes = _balanceMillimesFrom(balanceSnap.data()!);
        // Reverse the original delta (which was exactly cfMillimes, signed).
        final newMillimes = currentMillimes - cfMillimes;

        transaction.update(balanceRef, {'amountMillimes': newMillimes});
        transaction.update(cashflowRef, {'isDeleted': true});
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
