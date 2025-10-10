import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/core/theme/theme.dart';
import '../../cashflow/data/models/cashflow.dart';
import 'package:intl/intl.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<Cashflow> cashflows;

  const WeeklyBarChart({super.key, required this.cashflows});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int touchedGroupIndex = -1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final eightWeeksAgoStart = currentWeekStart.subtract(const Duration(days: 49));

    final expenses = widget.cashflows
        .where((c) => c.amount < 0 && !c.date.isBefore(eightWeeksAgoStart))
        .toList();

    final List<double> weeklyAmounts = List.filled(8, 0.0);
    final List<DateTime> weekStarts = [];
    DateTime weekStart = eightWeeksAgoStart;
    for (int i = 0; i < 8; i++) {
      weekStarts.add(weekStart);
      weekStart = weekStart.add(const Duration(days: 7));
    }

    for (var c in expenses) {
      final expenseDay = DateTime(c.date.year, c.date.month, c.date.day);
      final weekIndex = expenseDay.difference(eightWeeksAgoStart).inDays ~/ 7;
      if (weekIndex >= 0 && weekIndex < 8) {
        weeklyAmounts[weekIndex] += c.amount.abs();
      }
    }

    final hasData = weeklyAmounts.any((amount) => amount > 0);
    final maxY = hasData
        ? weeklyAmounts.reduce((a, b) => a > b ? a : b) * 1.2
        : 100; // arbitrary default height so chart looks normal when empty

    return Card(
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
              'Weekly Expenses (Last 8 Weeks)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: hasData
                  ? BarChart(
                      BarChartData(
                        maxY: maxY.toDouble(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final amount = rod.toY;
                              final weekStart = weekStarts[group.x.toInt()];
                              final label =
                                  'Week of ${DateFormat.MMMd().format(weekStart)}\n\$${amount.toStringAsFixed(2)}';
                              return BarTooltipItem(
                                label,
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          touchCallback: (FlTouchEvent event, barTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  barTouchResponse == null ||
                                  barTouchResponse.spot == null) {
                                touchedGroupIndex = -1;
                                return;
                              }
                              touchedGroupIndex =
                                  barTouchResponse.spot!.touchedBarGroupIndex;
                            });
                          },
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= 8) {
                                  return const SizedBox.shrink();
                                }
                                final date = weekStarts[index];
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    DateFormat.Md().format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8,
                                  child: Text(
                                    '\$${value.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles:
                              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles:
                              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(8, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: weeklyAmounts[i],
                                color: touchedGroupIndex == i
                                    ? Colors.deepOrange
                                    : Colors.orange,
                                width: 18,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    )
                  : Center(
                      child: Text(
                        'No expenses in the last 8 weeks',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
