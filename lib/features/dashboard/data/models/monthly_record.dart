/// Precomputed per-month aggregates — income, expenses, and spend broken
/// down by category. Built once whenever the underlying cashflows change
/// (see `DashboardNotifier._rebuildMonthlyRecords`), so callers that just
/// need "totals for month X" (e.g. the donut chart's month navigator) do a
/// cheap lookup instead of re-filtering and re-summing the full cashflow
/// list on every read.
class MonthlyRecord {
  final int year;
  final int month; // 1-12

  final double income;
  final double expenses;
  final Map<String, double> spendByCategory;

  const MonthlyRecord({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
    required this.spendByCategory,
  });

  DateTime get monthStart => DateTime(year, month, 1);
}
