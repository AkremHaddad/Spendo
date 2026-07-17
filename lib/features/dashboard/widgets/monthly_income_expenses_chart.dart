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
    final theme = Theme.of(context);
    final now = DateTime.now();

    final List<DateTime> months = List.generate(6, (i) {
      return DateTime(now.year, now.month - i, 1);
    }).reversed.toList();

    final Map<String, double> incomePerMonth = {};
    final Map<String, double> expensesPerMonth = {};

    for (var month in months) {
      final key = DateFormat.yMMM().format(month);
      incomePerMonth[key] = 0.0;
      expensesPerMonth[key] = 0.0;
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

    final rawMax = [...incomePerMonth.values, ...expensesPerMonth.values]
        .fold<double>(0, (prev, e) => e > prev ? e : prev);
    final maxY = rawMax > 0 ? rawMax * 1.2 : 1.0;

    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (v) => FlLine(color: theme.border, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${currency.format(rod.toY)}',
                TextStyle(color: theme.ink, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.MMM().format(months[index]),
                    style: TextStyle(fontSize: 10, color: theme.ink2),
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
                    style: TextStyle(fontSize: 10, color: theme.ink2),
                  ),
                );
              },
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
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: income,
                color: theme.tintMintInk,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: expense,
                color: theme.tintCoralInk,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
