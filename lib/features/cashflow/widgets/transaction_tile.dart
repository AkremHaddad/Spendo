// lib/features/cashflow/presentation/transaction_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/cashflow.dart';
import '../../../core/theme/theme.dart';
import '../widgets/grid_card.dart'; // adjust path if needed
import '../widgets/transaction_edit_dialog.dart'; // adjust path if needed
import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';

class TransactionTile extends StatelessWidget {
  final Cashflow cashflow;
  final Map<String, String>? categoryNames; // categoryId -> name (non-deleted)
  final Map<String, Map<String, String>>? productNames; // categoryId -> {productId -> name}

  const TransactionTile({
    super.key,
    required this.cashflow,
    this.categoryNames,
    this.productNames,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1) Try the provided categoryNames map first (fast, existing behavior)
    String? resolvedCategoryName = categoryNames?[cashflow.categoryId];

    // 2) If not found, try to read from CategoryNotifier.allCategories (includes soft-deleted)
    if (resolvedCategoryName == null) {
      try {
        final catNotifier = Provider.of<CategoryNotifier>(context, listen: false);
        final matches = catNotifier.allCategories.where((c) => c.id == cashflow.categoryId);
        if (matches.isNotEmpty) {
          resolvedCategoryName = matches.first.name;
        }
      } catch (_) {
        // ignore - if notifier not available, we will fall back below
      }
    }

    // final fallback
    final categoryName = resolvedCategoryName ?? 'Unknown';

    // Product name: try provided map, otherwise try to find on the category (even if deleted)
    String productName = '-';
    if (cashflow.productId != null) {
      productName = productNames?[cashflow.categoryId]?[cashflow.productId!] ?? cashflow.productId!;
      // Try to resolve via CategoryNotifier products if it still looks like an id
      if (productName == cashflow.productId!) {
        try {
          final catNotifier = Provider.of<CategoryNotifier>(context, listen: false);
          final cat = catNotifier.allCategories.firstWhere(
            (c) => c.id == cashflow.categoryId,
            orElse: () => Category(id: '', name: '', color: Colors.transparent, type: CategoryType.expense, userId: ''),
          );
          if (cat.id.isNotEmpty) {
            final prodMatch = cat.products.where((p) => p.id == cashflow.productId).toList();
            if (prodMatch.isNotEmpty) productName = prodMatch.first.name;
          }
        } catch (_) {
          // ignore and keep the id fallback
        }
      }
    }

    final displayAmount = cashflow.isExpense
        ? '-${cashflow.amount.abs().toStringAsFixed(2)}'
        : cashflow.amount.toStringAsFixed(2);

    // tile tint uses a very subtle primary color tint
    final tileTint = cashflow.isExpense
        ? Theme.of(context).primaryColorCustom.withOpacity(0.03)
        : Theme.of(context).primaryColorCustom.withOpacity(0.04);

    return GridCard(
      height: 90,
      backgroundColor: tileTint,
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => TransactionEditDialog(cashflow: cashflow),
        );
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
