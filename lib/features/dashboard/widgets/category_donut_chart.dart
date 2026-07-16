import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../../categories/data/models/category.dart';
import '../../../core/theme/theme.dart';
import '../presentation/dashboard_page.dart' show catEmoji;

/// Category spend breakdown as a donut, with a hover-driven center label
/// and a side legend — content only, the caller provides the card chrome
/// (same split as [MonthlyIncomeExpensesChart]).
class CategoryDonutChart extends StatefulWidget {
  final List<Cashflow> cashflows;
  final List<Category> categories;

  /// Whether the donut and legend should stack vertically instead of
  /// sitting side by side. Passed in by the caller (rather than measured
  /// internally via LayoutBuilder) because this card sometimes needs to sit
  /// inside an IntrinsicHeight for row-height matching, and LayoutBuilder
  /// can't be measured intrinsically — Flutter throws
  /// "LayoutBuilder does not support returning intrinsic dimensions".
  final bool stacked;

  const CategoryDonutChart({
    super.key,
    required this.cashflows,
    required this.categories,
    this.stacked = false,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _Slice {
  final String name;
  final Color color;
  final double value;
  const _Slice({required this.name, required this.color, required this.value});
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final spendByCat = <String, double>{};
    for (final c in widget.cashflows.where((c) => c.isExpense)) {
      spendByCat[c.categoryId] = (spendByCat[c.categoryId] ?? 0) + c.amount.abs();
    }

    if (spendByCat.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No spending yet this month', style: theme.sans(13.5, color: theme.ink2)),
        ),
      );
    }

    final catById = {for (final c in widget.categories) c.id: c};
    final entries = spendByCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final slices = entries.map((e) {
      final cat = catById[e.key];
      return _Slice(name: cat?.name ?? 'Unknown', color: cat?.color ?? theme.ink3, value: e.value);
    }).toList();
    final total = slices.fold(0.0, (s, sl) => s + sl.value);
    final active = (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < slices.length)
        ? slices[_touchedIndex!]
        : null;

    return _buildContent(context, theme, slices, total, active, widget.stacked);
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    List<_Slice> slices,
    double total,
    _Slice? active,
    bool stacked,
  ) {
    final donutSize = stacked ? 160.0 : 180.0;
    final donut = SizedBox(
      width: donutSize,
      height: donutSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: stacked ? 56 : 64,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    final index = response?.touchedSection?.touchedSectionIndex;
                    if (!event.isInterestedForInteractions || index == null || index < 0) {
                      _touchedIndex = null;
                      return;
                    }
                    _touchedIndex = index;
                  });
                },
              ),
              sections: List.generate(slices.length, (i) {
                final isTouched = i == _touchedIndex;
                return PieChartSectionData(
                  color: slices[i].color,
                  value: slices[i].value,
                  radius: isTouched ? 34 : 28,
                  showTitle: false,
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: active != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(catEmoji(active.name), style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text('\$${active.value.toStringAsFixed(0)}', style: theme.serif(22)),
                      Text(
                        '${(active.value / total * 100).round()}% · ${active.name}',
                        style: theme.sans(10.5, color: theme.ink2),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TOTAL', style: theme.sans(10.5, weight: FontWeight.w700, color: theme.ink2)),
                      Text('\$${total.toStringAsFixed(0)}', style: theme.serif(26)),
                    ],
                  ),
          ),
        ],
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: slices.take(6).map((s) {
        final pct = (s.value / total * 100).round();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.name, style: theme.sans(12.5), overflow: TextOverflow.ellipsis),
              ),
              Text('$pct%', style: theme.mono(12, color: theme.ink2)),
            ],
          ),
        );
      }).toList(),
    );

    if (stacked) {
      return Column(
        children: [
          donut,
          const SizedBox(height: 16),
          legend,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: 24),
        Expanded(child: legend),
      ],
    );
  }
}
