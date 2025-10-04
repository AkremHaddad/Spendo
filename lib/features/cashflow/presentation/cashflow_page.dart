import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/cashflowNotifier.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../data/models/cashflow.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/transaction_tile.dart';

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
      if (!notifier.loadedToday) notifier.loadTodayCashflows();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.cardColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer2<CashflowNotifier, CategoryNotifier>(
          builder: (context, cashflowNotifier, categoryNotifier, _) {
            final transactions = cashflowNotifier.cashflows;

            // Maps for category and product names
            final categoryNames = {for (var c in categoryNotifier.categories) c.id: c.name};
            final productNames = {
              for (var c in categoryNotifier.categories)
                c.id: {for (var p in c.products) p.id: p.name}
            };

            // Calculate total expenses for selected date
            final selectedExpenses = transactions
                .where((t) =>
                    t.date.year == selectedDate.year &&
                    t.date.month == selectedDate.month &&
                    t.date.day == selectedDate.day &&
                    t.amount < 0)
                .fold(0.0, (sum, t) => sum + t.amount.abs());

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cashflow',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      // Date container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Day number
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.primaryColorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${selectedDate.day}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Day name / month-year
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_dayName(selectedDate.weekday)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_monthName(selectedDate.month)} ${selectedDate.year}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Expenses
                            Column(
                              children: [
                                const Text(
                                  'Expenses',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ===== Transactions Grid =====
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...transactions.map((tx) {
                        return SizedBox(
                          width: 300,
                          child: TransactionTile(
                            cashflow: tx,
                            categoryNames: categoryNames,
                            productNames: productNames,
                          ),
                        );
                      }).toList(),
                      // Add Transaction card
                      SizedBox(
                        width: 300,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => ChangeNotifierProvider.value(
                                value: cashflowNotifier,
                                child: const AddTransactionForm(),
                              ),
                            );
                          },
                          child: Container(
                            height: 120,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.cardColor,
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: const Center(
                              child: Text(
                                'Add Transaction',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
