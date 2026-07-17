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

    // Prepare last 7 days (oldest → newest)
    for (int i = 6; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyExpenses[day] = 0.0;
    }

    // Aggregate expenses
    for (var c in cashflows.where((c) => c.amount < 0)) {
      final day = DateTime(c.date.year, c.date.month, c.date.day);
      if (dailyExpenses.containsKey(day)) {
        dailyExpenses[day] =
            dailyExpenses[day]! + c.amount.abs();
      }
    }

    final totalExpenses =
        dailyExpenses.values.fold<double>(0, (sum, v) => sum + v);

    // Build bars
    final barGroups = dailyExpenses.entries.map((entry) {
      final x =
          entry.key.difference(dailyExpenses.keys.first).inDays;
      return BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.redAccent,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    // Max Y with headroom
    final rawMaxY =
        dailyExpenses.values.fold<double>(0, (prev, e) => e > prev ? e : prev);
    final chartMaxY = rawMaxY > 0 ? rawMaxY * 1.2 : 1.0;

    // Formatter → 3 decimals
    final currency3Decimals =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return SizedBox(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                    ? const Center(
                        child: Text(
                          'No expenses recorded this week',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          maxY: chartMaxY,
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(
                            show: true,
                            border:
                                Border.all(color: Colors.black, width: 1),
                          ),

                          /// TOOLTIP
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final day = dailyExpenses.keys.first
                                    .add(Duration(days: group.x));
                                return BarTooltipItem(
                                  '${DateFormat.E().format(day)}\n'
                                  '${currency3Decimals.format(rod.toY)}',
                                  const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),

                          /// AXES
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final day = dailyExpenses.keys.first
                                      .add(Duration(days: value.toInt()));
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Text(
                                      DateFormat.E().format(day),
                                      style:
                                          const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 56,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8,
                                    child: Text(
                                      '\$${value.toStringAsFixed(0)}',
                                      style:
                                          const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
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
