import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../categories/data/models/category.dart';
import '../../categories/category_style_options.dart';
import '../data/models/monthly_record.dart';
import '../../../core/theme/theme.dart';

/// Category spend breakdown as a donut, with prev/next arrows to browse
/// the last 6 months' [MonthlyRecord]s — content only, the caller provides
/// the card chrome (same split as [MonthlyIncomeExpensesChart]).
class CategoryDonutChart extends StatefulWidget {
  final List<MonthlyRecord> monthlyRecords;
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
    required this.monthlyRecords,
    required this.categories,
    this.stacked = false,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _Slice {
  final String name;
  final Color color;
  final IconData icon;
  final double value;
  const _Slice({required this.name, required this.color, required this.icon, required this.value});
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;
  late int _monthIndex;

  @override
  void initState() {
    super.initState();
    _monthIndex = widget.monthlyRecords.length - 1; // default to the current month
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_monthIndex >= widget.monthlyRecords.length) {
      _monthIndex = widget.monthlyRecords.length - 1;
    }
  }

  void _goToPrevMonth() {
    if (_monthIndex <= 0) return;
    setState(() {
      _monthIndex--;
      _touchedIndex = null;
    });
  }

  void _goToNextMonth() {
    if (_monthIndex >= widget.monthlyRecords.length - 1) return;
    setState(() {
      _monthIndex++;
      _touchedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = widget.monthlyRecords[_monthIndex];
    final spendByCat = record.spendByCategory;

    final catById = {for (final c in widget.categories) c.id: c};
    final entries = spendByCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final slices = entries.map((e) {
      final cat = catById[e.key];
      return _Slice(
        name: cat?.name ?? 'Unknown',
        color: cat != null ? colorForCategoryKey(cat.colorKey, theme.brightness) : theme.ink3,
        icon: cat != null ? iconForCategoryKey(cat.icon) : Icons.category_rounded,
        value: e.value,
      );
    }).toList();
    final total = slices.fold(0.0, (s, sl) => s + sl.value);
    final active = (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < slices.length)
        ? slices[_touchedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthNavRow(
          theme: theme,
          label: DateFormat.yMMMM().format(record.monthStart),
          canGoPrev: _monthIndex > 0,
          canGoNext: _monthIndex < widget.monthlyRecords.length - 1,
          onPrev: _goToPrevMonth,
          onNext: _goToNextMonth,
        ),
        const SizedBox(height: 14),
        if (slices.isEmpty)
          SizedBox(
            height: 180,
            child: Center(
              child: Text('No spending that month', style: theme.sans(13.5, color: theme.ink2)),
            ),
          )
        else
          _buildContent(context, theme, slices, total, active, widget.stacked),
      ],
    );
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
                      Icon(active.icon, size: 24, color: active.color),
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

class _MonthNavRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavRow({
    required this.theme,
    required this.label,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavArrow(theme: theme, icon: Icons.chevron_left_rounded, enabled: canGoPrev, onTap: onPrev),
        Text(label, style: theme.sans(13, weight: FontWeight.w600)),
        _NavArrow(theme: theme, icon: Icons.chevron_right_rounded, enabled: canGoNext, onTap: onNext),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.theme,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: enabled ? theme.ink : theme.ink3),
      ),
    );
  }
}
