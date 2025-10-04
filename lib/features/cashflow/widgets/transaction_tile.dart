import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/cashflow.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';


class TransactionTile extends StatelessWidget {
  final Cashflow cashflow;
  final Map<String, String>? categoryNames; // categoryId -> name
  final Map<String, Map<String, String>>? productNames; // categoryId -> {productId -> name}

  const TransactionTile({
    super.key,
    required this.cashflow,
    this.categoryNames,
    this.productNames,
  });

  @override
  Widget build(BuildContext context) {
    // Lookup category name (fallback to id)
    final categoryName = categoryNames?[cashflow.categoryId] ?? cashflow.categoryId;

    // Lookup product name (fallback to id or '-')
    final productName = (cashflow.productId != null)
        ? (productNames?[cashflow.categoryId]?[cashflow.productId!] ?? cashflow.productId!)
        : '-';

    final displayAmount = cashflow.isExpense
        ? '-${cashflow.amount.abs().toStringAsFixed(2)}'
        : cashflow.amount.toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row: category name (bold) and amount on the right
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  displayAmount,
                  style: TextStyle(
                    color: cashflow.isExpense ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Product line
            Text('Product: $productName', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 6),
            // Date (small)
            Text(
              '${cashflow.date.day}/${cashflow.date.month}/${cashflow.date.year}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
