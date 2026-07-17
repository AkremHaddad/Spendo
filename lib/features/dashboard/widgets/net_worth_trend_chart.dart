import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../../../core/theme/theme.dart';

/// Net worth over the last 30 days, reconstructed by walking the current
/// balance backwards day-by-day through each day's net cashflow change (so
/// the most recent point always matches the real current balance) —
/// content only, the caller renders the card chrome (same split as
/// [ForecastAreaChart]/[MonthlyIncomeExpensesChart]).
class NetWorthTrendChart extends StatelessWidget {
  final List<Cashflow> cashflows;
  final double currentBalance;
  final double height;

  const NetWorthTrendChart({
    super.key,
    required this.cashflows,
    required this.currentBalance,
    this.height = 80,
  });

  static const _days = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: _days - 1));

    final dailyChange = List<double>.filled(_days, 0.0);
    for (final c in cashflows) {
      final day = DateTime(c.date.year, c.date.month, c.date.day);
      if (day.isBefore(start) || day.isAfter(today)) continue;
      dailyChange[day.difference(start).inDays] += c.amount;
    }

    final balances = List<double>.filled(_days, 0.0);
    double running = currentBalance;
    for (int i = _days - 1; i >= 0; i--) {
      balances[i] = running;
      running -= dailyChange[i];
    }

    final minY = balances.reduce((a, b) => a < b ? a : b);
    final maxY = balances.reduce((a, b) => a > b ? a : b);
    final span = maxY - minY;
    final pad = span < 1 ? 1.0 : span * 0.15;

    final positive = balances.last >= balances.first;
    final lineColor = positive ? theme.tintMintInk : theme.tintCoralInk;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((s) {
                final date = start.add(Duration(days: s.x.toInt()));
                return LineTooltipItem(
                  '${date.month}/${date.day}\n\$${s.y.toStringAsFixed(0)}',
                  TextStyle(color: theme.surface, fontWeight: FontWeight.w600, fontSize: 11),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(_days, (i) => FlSpot(i.toDouble(), balances[i])),
              isCurved: true,
              curveSmoothness: 0.25,
              color: lineColor,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lineColor.withOpacity(0.28), lineColor.withOpacity(0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
