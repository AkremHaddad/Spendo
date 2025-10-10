import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../categories/logic/categoryNotifier.dart';
import '../logic/dashboardNotifier.dart';
import '../../../core/theme/theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/income_card.dart';
import '../widgets/expenses_card.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/daily_line_chart.dart';
import '../widgets/balance_line_chart.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/monthly_income_expenses_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showEditBalanceDialog(
    BuildContext context,
    DashboardNotifier notifier,
  ) {
    final TextEditingController controller = TextEditingController(
      text: notifier.balance.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Balance'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Enter new balance'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).baseContent),
              ),
            ),
            TextButton(
              onPressed: () {
                final double? newBalance = double.tryParse(controller.text);
                if (newBalance != null) {
                  notifier.updateBalance(newBalance);
                }
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(color: Theme.of(context).baseContent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<DashboardNotifier>(context);
    final categoryNotifier = Provider.of<CategoryNotifier>(context);

    if (notifier.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).base300,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              color: Theme.of(context).base300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).baseContent,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showEditBalanceDialog(context, notifier),
                    child: const Text(
                      'Edit Balance',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // const SizedBox(height: 8),

            // ===== First Row =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Pie Chart
                SizedBox(
                  height: 384,
                  width: 400,
                  child: CategoryPieChart(
                    cashflows: notifier.last30DaysCashflows,
                    categories: categoryNotifier.allCategories,
                  ),
                ),
                const SizedBox(width: 16),
                // Right: Container A
                Expanded(
                  child: Column(
                    children: [
                      // Row 1: Cards
                      Row(
                        children: [
                          Expanded(
                            child: BalanceCard(balance: notifier.balance),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: IncomeCard(income: notifier.monthIncome),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ExpensesCard(
                              expenses: notifier.monthExpenses,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 2: DailyLineChart & WeeklyBarChart
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DailyLineChart(
                              cashflows: notifier.last7DaysCashflows,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: WeeklyBarChart(
                              cashflows: notifier.last30DaysCashflows,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ===== Second Row =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BalanceLineChart(
                    cashflows: notifier.last30DaysCashflows,
                    initialBalance: notifier.balance,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MonthlyIncomeExpensesChart(
                    cashflows: notifier.last6MonthsCashflows,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
