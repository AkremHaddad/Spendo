// lib/features/dashboard/widgets/category_pie_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../../categories/data/models/category.dart'; // so we can use category colors
import 'package:flutter_application_1/core/theme/theme.dart';

class CategoryPieChart extends StatefulWidget {
  final List<Cashflow> cashflows;
  final List<Category> categories;

  const CategoryPieChart({
    super.key,
    required this.cashflows,
    required this.categories,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    // 🔹 Filter only expenses from the last 30 days
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final expenses = widget.cashflows
        .where((c) => c.amount < 0 && c.date.isAfter(start))
        .toList();

    // 🔹 Aggregate totals per category
    final Map<String, double> dataMap = {};
    for (var c in expenses) {
      dataMap[c.categoryId] = (dataMap[c.categoryId] ?? 0) + c.amount.abs();
    }
    final borderColor = Theme.of(context).borderColor;

    if (dataMap.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(width: 1, color: borderColor),
        ),
        elevation: 4,
        child: const SizedBox(
          height: 240,
          child: Center(
            child: Text(
              'No expenses in the last 30 days',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final total = dataMap.values.fold(0.0, (p, e) => p + e);

    // 🔹 Build sections with real category colors
    final sections = <PieChartSectionData>[];
    final categoryIds = dataMap.keys.toList();
    for (int i = 0; i < categoryIds.length; i++) {
      final categoryId = categoryIds[i];
      final amount = dataMap[categoryId]!;
      final category = widget.categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => Category(
          id: categoryId,
          name: 'Unknown',
          color: Colors.grey,
          type: CategoryType.expense,
          userId: '',
        ),
      );

      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 13.0;
      final radius = isTouched ? 75.0 : 65.0;
      final percentage = total > 0 ? (amount / total) * 100 : 0.0;

      // <-- PIE: kept original behaviour (shows percentage by default,
      // shows name + percentage when touched) - NOT CHANGED
      final title = isTouched
          ? '${category.name}\n${percentage.toStringAsFixed(1)}%'
          : '${percentage.toStringAsFixed(1)}%';

      sections.add(
        PieChartSectionData(
          color: category.color,
          value: amount,
          title: title,
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 2, color: Colors.black45)],
          ),
        ),
      );
    }

    // Legend list items (ordered to match pie slices)
    final legendItems = categoryIds.map((id) {
      final amount = dataMap[id]!;
      final category = widget.categories.firstWhere(
        (cat) => cat.id == id,
        orElse: () => Category(
          id: id,
          name: 'Unknown',
          color: Colors.grey,
          type: CategoryType.expense,
          userId: '',
        ),
      );
      final percent = total > 0 ? (amount / total) * 100 : 0.0;
      return _LegendItemData(
        id: id,
        name: category.name,
        color: category.color,
        amount: amount,
        percent: percent,
      );
    }).toList();

    return Container(
      width: 600,
      child: Card(
        color: Theme.of(context).cardsColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(width: 1, color: borderColor),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Expenses per Category (Last 30 Days)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Keep the pie exactly as it was
              SizedBox(
                height: 210,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = null;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== Legend: fixed height, bottom-stuck, horizontally scrollable =====
              // Shows only category name by default. On hover, Tooltip pops up above item displaying
              // amount + percentage. Keeps a small visible chip for color.
              // ===== Legend (multi-line wrapping, no overflow) =====
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: legendItems.map((item) {
                    final tooltipMsg =
                        '${item.name}\n\$${item.amount.toStringAsFixed(2)} • ${item.percent.toStringAsFixed(1)}%';
                    return Tooltip(
                      message: tooltipMsg,
                      preferBelow: false,
                      verticalOffset: 8,
                      showDuration: const Duration(milliseconds: 1800),
                      waitDuration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      textStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(item.name, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItemData {
  final String id;
  final String name;
  final Color color;
  final double amount;
  final double percent;

  _LegendItemData({
    required this.id,
    required this.name,
    required this.color,
    required this.amount,
    required this.percent,
  });
}
