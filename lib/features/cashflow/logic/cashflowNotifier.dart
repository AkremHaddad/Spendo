import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/cashflow.dart';

class CashflowNotifier extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool _loadedToday = false;
  List<Cashflow> _cashflows = [];
  List<Cashflow> get cashflows => _cashflows;

  CashflowNotifier({required this.userId});

  /// Load only today's transactions once
  Future<void> loadTodayCashflows() async {
    if (_loadedToday) return;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
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
          .map((doc) => Cashflow.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      _loadedToday = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('Error loading today cashflows: $e\n$st');
    }
  }

  /// Force reload today's transactions
  Future<void> reloadTodayCashflows() async {
    _loadedToday = false;
    await loadTodayCashflows();
  }

  /// Add new cashflow
  Future<void> addCashflow(Cashflow cashflow) async {
    try {
      final docRef = firestore.collection('cashflows').doc();
      final newCashflow = cashflow.copyWith(id: docRef.id);
      await docRef.set(newCashflow.toJson());

      final now = DateTime.now();
      final isToday = newCashflow.date.year == now.year &&
          newCashflow.date.month == now.month &&
          newCashflow.date.day == now.day;

      if (isToday) {
        _cashflows.insert(0, newCashflow);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('Error adding cashflow: $e\n$st');
    }
  }

  /// Soft delete
  Future<void> deleteCashflow(String id) async {
    try {
      await firestore.collection('cashflows').doc(id).update({'isDeleted': true});
      _cashflows.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e, st) {
      debugPrint('Error deleting cashflow: $e\n$st');
    }
  }

  /// Today's total expenses
  double get todayExpenses {
    final now = DateTime.now();
    return _cashflows
        .where((c) =>
            c.date.year == now.year &&
            c.date.month == now.month &&
            c.date.day == now.day)
        .where((c) => c.amount < 0)
        .fold(0.0, (sum, c) => sum + c.amount.abs());
  }

  /// Per-category expenses today
  Map<String, double> get todayCategoryExpenses {
    final now = DateTime.now();
    final Map<String, double> data = {};
    for (final c in _cashflows) {
      if (c.date.year == now.year &&
          c.date.month == now.month &&
          c.date.day == now.day &&
          c.amount < 0) {
        data[c.categoryId] = (data[c.categoryId] ?? 0) + c.amount.abs();
      }
    }
    return data;
  }

  bool get loadedToday => _loadedToday;

  @override
  void dispose() {
    super.dispose();
  }
}
