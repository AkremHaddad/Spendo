import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cashflow/data/models/cashflow.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';

class BalanceLineChart extends StatelessWidget {
  final List<Cashflow> cashflows;
  final double initialBalance;

  const BalanceLineChart({
    super.key,
    required this.cashflows,
    required this.initialBalance,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final nowDay = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final int totalDays = nowDay.difference(startDay).inDays + 1;

    // Filter cashflows within the last 30 days
    final filteredCashflows = cashflows.where((c) => !c.date.isBefore(start) && !c.date.isAfter(now)).toList();

    // Aggregate daily changes
    final Map<DateTime, double> dailyChanges = {};
    for (var c in filteredCashflows) {
      final day = DateTime(c.date.year, c.date.month, c.date.day);
      dailyChanges[day] = (dailyChanges[day] ?? 0) + c.amount;
    }

    // Compute balance spots backwards
    final List<FlSpot> spots = [];
    double balance = initialBalance;
    DateTime day = nowDay;
    for (int i = totalDays - 1; i >= 0; i--) {
      spots.add(FlSpot(i.toDouble(), balance));
      final change = dailyChanges[day] ?? 0;
      balance -= change;
      day = day.subtract(const Duration(days: 1));
    }

    if (spots.isEmpty) {
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
        child: const SizedBox(
          height: 240,
          child: Center(
            child: Text(
              'No balance data in the last 30 days',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.1;

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
                'Balance Over Last 30 Days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: minY - yPadding,
                    maxY: maxY + yPadding,
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
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= totalDays) return const SizedBox.shrink();
                            final date = startDay.add(Duration(days: index));
                            return SideTitleWidget(
                              angle: 0,
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
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              '\$${value.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.toInt();
                            final date = startDay.add(Duration(days: index));
                            final bal = spot.y;
                            return LineTooltipItem(
                              '${DateFormat.yMd().format(date)}\n\$${bal.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
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
