import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../../../core/theme/theme.dart';

class DailyLineChart extends StatelessWidget {
  final List<Cashflow> cashflows;

  const DailyLineChart({super.key, required this.cashflows});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<DateTime, double> dailyExpenses = {};

    // Prepare last 7 days
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyExpenses[day] = 0.0;
    }

    // Aggregate expenses
    for (var c in cashflows.where((c) => c.amount < 0)) {
      final day = DateTime(c.date.year, c.date.month, c.date.day);
      if (dailyExpenses.containsKey(day)) {
        dailyExpenses[day] = dailyExpenses[day]! + c.amount.abs();
      }
    }

    final totalExpenses = dailyExpenses.values.fold<double>(0, (sum, v) => sum + v);

    final barGroups = dailyExpenses.entries.map((e) {
      final x = e.key.difference(dailyExpenses.keys.first).inDays.toDouble();
      return BarChartGroupData(
        x: x.toInt(),
        barRods: [
          BarChartRodData(
            toY: e.value,
            color: Colors.redAccent,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final maxY = dailyExpenses.values.fold<double>(0, (prev, e) => e > prev ? e : prev) * 1.2;

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
                'Daily Expenses (Last 7 Days)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: totalExpenses == 0
                    ? const Center(child: Text('No expenses recorded this week', style: TextStyle(color: Colors.grey)))
                    : BarChart(
                        BarChartData(
                          maxY: maxY,
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final day = dailyExpenses.keys.first.add(Duration(days: value.toInt()));
                                  final label = DateFormat.E().format(day);
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
                                reservedSize: 48,
                                getTitlesWidget: (value, meta) => SideTitleWidget(
                                  meta: meta,
                                  space: 8,
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
                          barGroups: barGroups,
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
