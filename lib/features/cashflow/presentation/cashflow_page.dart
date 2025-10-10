import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/cashflowNotifier.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../data/models/cashflow.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/transaction_tile.dart';
import '../../../core/theme/theme.dart';
import '../widgets/grid_card.dart';

class NoScrollBarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<CashflowNotifier>();
      final lastDate = notifier.lastSelectedDate ?? DateTime.now();
      setState(() => selectedDate = lastDate);
      notifier.loadCashflowsForDate(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).base300,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Consumer2<CashflowNotifier, CategoryNotifier>(
          builder: (context, cashflowNotifier, categoryNotifier, _) {
            final transactions = cashflowNotifier.cashflows;

            // Maps for category and product names
            final categoryNames = {
              for (var c in categoryNotifier.categories) c.id: c.name,
            };
            final productNames = {
              for (var c in categoryNotifier.categories)
                c.id: {for (var p in c.products) p.id: p.name},
            };

            // Calculate total expenses for selected date
            final selectedExpenses = transactions
                .where(
                  (t) =>
                      t.date.year == selectedDate.year &&
                      t.date.month == selectedDate.month &&
                      t.date.day == selectedDate.day &&
                      t.amount < 0,
                )
                .fold(0.0, (sum, t) => sum + t.amount.abs());

            return ScrollConfiguration(
              behavior: NoScrollBarBehavior(),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Header Container =====
                    Container(
                      height: 80,
                      width: 999,
                      padding: const EdgeInsets.all(0),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cashflow',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).baseContent,
                            ),
                          ),
                          // Date container
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null && picked != selectedDate) {
                                  setState(() => selectedDate = picked);
                                  cashflowNotifier.setLastSelectedDate(picked);
                                  cashflowNotifier.loadCashflowsForDate(picked);
                                }
                              },
                              child: Container(
                                height: 62,
                                width: 350,
                                padding: const EdgeInsets.all(6),
                                // margin: const EdgeInsets.only(right: 300),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).base100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize
                                      .max, // Changed to max to fill available width
                                  children: [
                                    // Day number
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${selectedDate.day}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).baseContent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Day name / month-year
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_dayName(selectedDate.weekday)}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).baseContent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_monthName(selectedDate.month)} ${selectedDate.year}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).baseContent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(), // Replaced SizedBox with Spacer to push expenses to the right
                                    // Expenses
                                    Column(
                                      children: [
                                        Text(
                                          'Expenses',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).baseContent,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          selectedExpenses.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Transactions Container =====
                    Container(
                      width: 999,
                      padding: const EdgeInsets.all(9),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double itemWidth = 307;
                          const double spacing = 30;
                          final double maxWidth = constraints.maxWidth;
                          if (itemWidth > maxWidth) {
                            itemWidth = maxWidth;
                          }

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              ...transactions.map(
                                (tx) => SizedBox(
                                  width: itemWidth,
                                  child: TransactionTile(
                                    cashflow: tx,
                                    categoryNames: categoryNames,
                                    productNames: productNames,
                                  ),
                                ),
                              ),
                              // Add Transaction card
                              SizedBox(
                                width: itemWidth,
                                child: GridCard(
                                  height: 90,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => ChangeNotifierProvider.value(
                                        value:
                                            cashflowNotifier, // just pass the notifier, don't wrap twice
                                        child: AddTransactionForm(
                                          initialDate: selectedDate,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_rounded,
                                          size: 28,
                                          color: theme.primaryColor,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Add Transaction',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
      default:
        return 'Sun';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
