import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class IncomeCard extends StatelessWidget {
  final double income;

  const IncomeCard({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.success,
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
                'Income (This Month)',
                style: TextStyle(color: theme.successContent, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${income.toStringAsFixed(2)}',
                style: TextStyle(
                  color: theme.successContent,
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