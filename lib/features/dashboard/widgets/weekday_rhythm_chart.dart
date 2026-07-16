import 'package:flutter/material.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../../../core/theme/theme.dart';

/// Average spend by day of week, over an 8-week trailing window (same
/// window as the weekly totals chart) — content only, matching the split
/// between chart and card chrome used across this feature.
class WeekdayRhythmChart extends StatelessWidget {
  final List<Cashflow> cashflows;

  const WeekdayRhythmChart({super.key, required this.cashflows});

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _windowDays = 55; // 8 weeks back, inclusive of today

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: _windowDays));

    final totals = List<double>.filled(7, 0.0);
    final occurrences = List<int>.filled(7, 0);
    for (int i = 0; i <= _windowDays; i++) {
      final day = windowStart.add(Duration(days: i));
      occurrences[day.weekday - 1]++;
    }
    for (final c in cashflows) {
      if (!c.isExpense) continue;
      final day = DateTime(c.date.year, c.date.month, c.date.day);
      if (day.isBefore(windowStart) || day.isAfter(today)) continue;
      totals[day.weekday - 1] += c.amount.abs();
    }
    final averages = List.generate(7, (i) => occurrences[i] > 0 ? totals[i] / occurrences[i] : 0.0);
    final maxV = averages.fold(0.0, (p, e) => e > p ? e : p);

    if (maxV <= 0) {
      return SizedBox(
        height: 150,
        child: Center(child: Text('Not enough data yet', style: theme.sans(13.5, color: theme.ink2))),
      );
    }

    final peakIdx = averages.indexOf(maxV);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(7, (i) {
          final isPeak = i == peakIdx;
          final heightFactor = (averages[i] / maxV).clamp(0.03, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Text(
                    '\$${averages[i].toStringAsFixed(0)}',
                    style: theme.mono(10, weight: FontWeight.w600, color: isPeak ? theme.tintCoralInk : theme.ink3),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFactor,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isPeak ? theme.tintCoralInk : theme.accentSoftColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _labels[i],
                    style: theme.sans(11, weight: isPeak ? FontWeight.w600 : FontWeight.w500, color: isPeak ? theme.ink : theme.ink2),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
