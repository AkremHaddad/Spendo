import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cashflow/data/models/cashflow.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';

class MonthlyIncomeExpensesChart extends StatelessWidget {
  final List<Cashflow> cashflows;

  const MonthlyIncomeExpensesChart({super.key, required this.cashflows});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Prepare last 6 months starting from current month
    final List<DateTime> months = List.generate(6, (i) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      return monthDate;
    }).reversed.toList(); // oldest first

    // Aggregate income and expenses per month
    final Map<String, double> incomePerMonth = {};
    final Map<String, double> expensesPerMonth = {};

    for (var month in months) {
      final key = DateFormat.yMMM().format(month);
      incomePerMonth[key] = 0;
      expensesPerMonth[key] = 0;
    }

    for (var c in cashflows) {
      final monthKey = DateFormat.yMMM().format(DateTime(c.date.year, c.date.month, 1));
      if (incomePerMonth.containsKey(monthKey)) {
        if (c.amount > 0) {
          incomePerMonth[monthKey] = incomePerMonth[monthKey]! + c.amount;
        } else {
          expensesPerMonth[monthKey] = expensesPerMonth[monthKey]! + c.amount.abs();
        }
      }
    }

    final maxY = [
      ...incomePerMonth.values,
      ...expensesPerMonth.values,
    ].fold<double>(0, (prev, e) => e > prev ? e : prev) * 1.2;

    return Container(
      width: 700,
      child: Card(
        color: Theme.of(context).cardsColor,


        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          width: 1,
          color: Theme.of(context).borderColor,
        ),
      ),
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Income vs Expenses (Last 6 Months)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= months.length) return const SizedBox.shrink();
                            final label = DateFormat.MMM().format(months[index]);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(label, style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48, // consistent with weekly chart
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            space: 8, // same gap as weekly chart
                            child: Text(
                              '\$${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: List.generate(months.length, (i) {
                      final key = DateFormat.yMMM().format(months[i]);
                      final income = incomePerMonth[key]!;
                      final expense = expensesPerMonth[key]!;

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: income,
                            color: Colors.green,
                            width: 18, // same width as weekly chart
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: expense,
                            color: Colors.redAccent,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        barsSpace: 6, // space between income & expense bars
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
