import 'package:flutter/material.dart';
import '../data/models/cashflow.dart';
import '../../../core/theme/theme.dart';
import 'package:provider/provider.dart';
import '../widgets/grid_card.dart'; // adjust path

class TransactionTile extends StatelessWidget {
  final Cashflow cashflow;
  final Map<String, String>? categoryNames; // categoryId -> name
  final Map<String, Map<String, String>>?
  productNames; // categoryId -> {productId -> name}

  const TransactionTile({
    super.key,
    required this.cashflow,
    this.categoryNames,
    this.productNames,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final categoryName =
        categoryNames?[cashflow.categoryId] ?? cashflow.categoryId;
    final productName = (cashflow.productId != null)
        ? (productNames?[cashflow.categoryId]?[cashflow.productId!] ??
              cashflow.productId!)
        : '-';

    final displayAmount = cashflow.isExpense
        ? '-${cashflow.amount.abs().toStringAsFixed(2)}'
        : cashflow.amount.toStringAsFixed(2);

    // tile tint uses a very subtle primary color tint; income slightly different if desired
    final tileTint = cashflow.isExpense
        ? Theme.of(context).primaryColorCustom.withOpacity(0.03)
        : Theme.of(context).primaryColorCustom.withOpacity(0.04);

    return GridCard(
      height: 100,
      backgroundColor: tileTint,
      onTap: () {
        // optional: show details or open edit UI on tap
        // Navigator.push(...);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                displayAmount,
                style: TextStyle(
                  color: cashflow.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Product: $productName',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ),
              Text(
                '${cashflow.date.day}/${cashflow.date.month}/${cashflow.date.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
