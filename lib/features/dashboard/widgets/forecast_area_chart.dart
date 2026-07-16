import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../../../core/theme/theme.dart';

/// Daily spend so far this month, as a filled area chart — content only,
/// the caller renders the headline/forecast number above it.
class ForecastAreaChart extends StatelessWidget {
  final List<Cashflow> cashflows;

  const ForecastAreaChart({super.key, required this.cashflows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daysElapsed = now.day;

    final daily = List<double>.filled(daysElapsed, 0.0);
    for (final c in cashflows) {
      if (!c.isExpense) continue;
      if (c.date.month != now.month || c.date.year != now.year) continue;
      final idx = c.date.day - 1;
      if (idx >= 0 && idx < daysElapsed) daily[idx] += c.amount.abs();
    }

    final maxV = daily.fold(0.0, (p, e) => e > p ? e : p);

    if (daysElapsed < 2 || maxV <= 0) {
      return SizedBox(
        height: 140,
        child: Center(child: Text('Not enough data yet this month', style: theme.sans(13.5, color: theme.ink2))),
      );
    }

    final spots = List.generate(daysElapsed, (i) => FlSpot(i.toDouble(), daily[i]));
    final maxY = maxV * 1.2;

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (v) => FlLine(color: theme.border, strokeWidth: 1, dashArray: const [2, 3]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched
                  .map((s) => LineTooltipItem(
                        'Day ${s.x.toInt() + 1}\n\$${s.y.toStringAsFixed(0)}',
                        TextStyle(color: theme.surface, fontWeight: FontWeight.w600, fontSize: 11),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: theme.tintLavenderInk,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.tintLavenderInk.withOpacity(0.32), theme.tintLavenderInk.withOpacity(0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
