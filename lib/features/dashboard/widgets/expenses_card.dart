import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class ExpensesCard extends StatelessWidget {
  final double expenses;

  const ExpensesCard({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.error,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Expenses (This Month)',
                style: TextStyle(color: theme.errorContent, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${expenses.toStringAsFixed(2)}',
                style: TextStyle(
                  color: theme.errorContent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}