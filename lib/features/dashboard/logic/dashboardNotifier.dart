import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../data/models/balance.dart';
import '../data/models/monthly_record.dart';
import '../../../core/utils/money.dart';

class _MonthAgg {
  double income = 0;
  double expenses = 0;
  final Map<String, double> spendByCategory = {};
}

class DashboardNotifier extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Cashflow> _cashflows = [];
  List<Cashflow> get cashflows => _cashflows;

  // Keyed by (year, month) — rebuilt once per cashflows snapshot (see
  // _rebuildMonthlyRecords), not on every read, so anything that just needs
  // "totals for month X" is a cheap lookup instead of a fresh scan over
  // every cashflow.
  Map<(int, int), MonthlyRecord> _monthlyRecords = {};

  Balance? _balanceObj;
  double get balance => _balanceObj?.amount ?? 0.0;

  /// Overall monthly budget goal (total spend target). Null = not set yet.
  double? get monthlyGoal => _balanceObj?.monthlyGoal;

  bool _loading = true;
  bool get loading => _loading;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _balanceSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cashflowsSub;

  DashboardNotifier({required this.userId}) {
    _loading = true;
    _startBalanceListener();
    _startCashflowsListener();
  }

  /// Live-updating cashflows list. This used to be a one-shot `.get()`,
  /// which is why the dashboard's charts only updated after a manual
  /// refresh (reopening the tab/page rebuilt the notifier) — switching to
  /// `.snapshots().listen()` makes it reactive like the balance already was.
  void _startCashflowsListener() {
    _cashflowsSub?.cancel();
    final query = firestore
        .collection('cashflows')
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true);

    _cashflowsSub = query.snapshots().listen((snapshot) {
      _cashflows = snapshot.docs
          .map((doc) => Cashflow.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();
      _rebuildMonthlyRecords();
      _loading = false;
      notifyListeners();
    }, onError: (err) {
      debugPrint('Error listening to cashflows: $err');
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> _startBalanceListener() async {
    await _balanceSub?.cancel();
    final docRef = firestore.collection('balances').doc(userId);

    // Ensure the doc exists before subscribing, same as before.
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      final newBalance = Balance(id: userId, userId: userId, amount: 0.0);
      await docRef.set(newBalance.toJson());
    }

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
      await docRef.set(
        {'userId': userId, 'amountMillimes': dinarsToMillimes(newAmount)},
        SetOptions(merge: true),
      );
      // local state will be updated by the snapshot listener quickly
    } catch (e, st) {
      debugPrint('Error updating balance: $e\n$st');
    }
  }

  /// Sets or clears the overall monthly budget goal (pass null to clear it).
  Future<void> updateMonthlyGoal(double? newGoal) async {
    try {
      final docRef = firestore.collection('balances').doc(userId);
      await docRef.set(
        {'userId': userId, 'monthlyGoalMillimes': newGoal == null ? null : dinarsToMillimes(newGoal)},
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('Error updating monthly goal: $e\n$st');
    }
  }

  /// Force reload everything — the listeners are live, so this just
  /// restarts them (useful e.g. after switching users).
  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    await _startBalanceListener();
    _startCashflowsListener();
  }

  @override
  void dispose() {
    _balanceSub?.cancel();
    _cashflowsSub?.cancel();
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

  /// Groups [_cashflows] into per-month totals (income, expenses, spend by
  /// category). Called once whenever a new cashflows snapshot arrives —
  /// everything that reads monthly aggregates (monthIncome/monthExpenses,
  /// last6MonthlyRecords) then just looks the answer up instead of
  /// re-scanning the full list.
  void _rebuildMonthlyRecords() {
    final agg = <(int, int), _MonthAgg>{};
    for (final c in _cashflows) {
      final key = (c.date.year, c.date.month);
      final a = agg.putIfAbsent(key, () => _MonthAgg());
      if (c.isIncome) {
        a.income += c.amount;
      } else if (c.isExpense) {
        final amt = c.amount.abs();
        a.expenses += amt;
        a.spendByCategory[c.categoryId] = (a.spendByCategory[c.categoryId] ?? 0) + amt;
      }
    }
    _monthlyRecords = {
      for (final e in agg.entries)
        e.key: MonthlyRecord(
          year: e.key.$1,
          month: e.key.$2,
          income: e.value.income,
          expenses: e.value.expenses,
          spendByCategory: e.value.spendByCategory,
        ),
    };
  }

  /// The last 6 calendar months (oldest → newest), always exactly 6 entries
  /// — a month with no activity yet gets a zero record rather than being
  /// skipped, so callers (e.g. the donut chart's month navigator) can index
  /// into this safely.
  List<MonthlyRecord> get last6MonthlyRecords {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final offset = 5 - i;
      final d = DateTime(now.year, now.month - offset, 1);
      return _monthlyRecords[(d.year, d.month)] ??
          MonthlyRecord(year: d.year, month: d.month, income: 0, expenses: 0, spendByCategory: {});
    });
  }

  double get monthIncome {
    final now = DateTime.now();
    return _monthlyRecords[(now.year, now.month)]?.income ?? 0.0;
  }

  double get monthExpenses {
    final now = DateTime.now();
    return _monthlyRecords[(now.year, now.month)]?.expenses ?? 0.0;
  }
}
