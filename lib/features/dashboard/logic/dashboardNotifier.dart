import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../data/models/balance.dart';

class DashboardNotifier extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Cashflow> _cashflows = [];
  List<Cashflow> get cashflows => _cashflows;

  Balance? _balanceObj;
  double get balance => _balanceObj?.amount ?? 0.0;

  bool _loading = true;
  bool get loading => _loading;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _balanceSub;

  DashboardNotifier({required this.userId}) {
    loadDashboardData().then((_) => _startBalanceListener());
  }

  /// Load cashflows and ensure a single balance doc exists at balances/{userId}
  Future<void> loadDashboardData() async {
    _loading = true;
    notifyListeners();

    try {
      final snapshot = await firestore
          .collection('cashflows')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();

      _cashflows = snapshot.docs
          .map((doc) => Cashflow.fromJson(doc.data() as Map<String, dynamic>)
              .copyWith(id: doc.id))
          .toList();
    } catch (e, st) {
      debugPrint('Error loading cashflows: $e\n$st');
      _cashflows = [];
    }

    try {
      final docRef = firestore.collection('balances').doc(userId);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        _balanceObj = Balance.fromJson(docSnap.data() as Map<String, dynamic>, id: docSnap.id);
      } else {
        // Create the doc with the userId as the doc id so it's unique and predictable
        final newBalance = Balance(id: userId, userId: userId, amount: 0.0);
        await docRef.set(newBalance.toJson());
        _balanceObj = newBalance;
      }
    } catch (e, st) {
      debugPrint('Error loading/creating balance doc: $e\n$st');
      _balanceObj = Balance(id: userId, userId: userId, amount: 0.0);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _startBalanceListener() async {
    await _balanceSub?.cancel();
    final docRef = firestore.collection('balances').doc(userId);

    _balanceSub = docRef.snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        try {
          _balanceObj = Balance.fromJson(snap.data() as Map<String, dynamic>, id: snap.id);
        } catch (e) {
          debugPrint('Error parsing balance snapshot: $e');
          _balanceObj = Balance(id: userId, userId: userId, amount: 0.0);
        }
      } else {
        // If removed externally, recreate with 0.0
        _balanceObj = Balance(id: userId, userId: userId, amount: 0.0);
        firestore.collection('balances').doc(userId).set(_balanceObj!.toJson());
      }
      notifyListeners();
    }, onError: (err) {
      debugPrint('Balance snapshot error: $err');
    });
  }

  /// Manual edit: update balances/{userId} (use merge to avoid overwriting other fields accidentally)
  Future<void> updateBalance(double newAmount) async {
    try {
      final docRef = firestore.collection('balances').doc(userId);
      await docRef.set({'userId': userId, 'amount': newAmount}, SetOptions(merge: true));
      // local state will be updated by the snapshot listener quickly
    } catch (e, st) {
      debugPrint('Error updating balance: $e\n$st');
    }
  }

  /// Force reload everything
  Future<void> reload() async {
    await loadDashboardData();
    await _startBalanceListener();
  }

  @override
  void dispose() {
    _balanceSub?.cancel();
    super.dispose();
  }

  // same filter helpers as before
  List<Cashflow> get todayCashflows {
    final now = DateTime.now();
    return _cashflows
        .where((c) =>
            c.date.year == now.year &&
            c.date.month == now.month &&
            c.date.day == now.day)
        .toList();
  }

  List<Cashflow> get last7DaysCashflows {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return _cashflows.where((c) => !c.date.isBefore(start)).toList();
  }

  List<Cashflow> get last30DaysCashflows {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 29));
    return _cashflows.where((c) => !c.date.isBefore(start)).toList();
  }

  List<Cashflow> get currentMonthCashflows {
    final now = DateTime.now();
    return _cashflows.where((c) => c.date.year == now.year && c.date.month == now.month).toList();
  }
List<Cashflow> get last6MonthsCashflows {
  final now = DateTime.now();
  final sixMonthsAgo = DateTime(now.year, now.month - 5, 1); // first day 6 months ago
  return _cashflows.where((c) => !c.date.isBefore(sixMonthsAgo)).toList();
}


  double get monthIncome =>
      currentMonthCashflows.where((c) => c.isIncome).fold(0.0, (s, c) => s + c.amount);

  double get monthExpenses =>
      currentMonthCashflows.where((c) => c.isExpense).fold(0.0, (s, c) => s + c.amount.abs());
}
