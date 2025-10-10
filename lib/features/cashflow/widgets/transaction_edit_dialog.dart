import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/cashflow.dart';
import '../logic/cashflowNotifier.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';
import '../../../core/theme/theme.dart';

import 'category_dropdown.dart';
import 'product_dropdown.dart';
import 'amount_input.dart';
import 'date_picker_field.dart';

class TransactionEditDialog extends StatefulWidget {
  final Cashflow cashflow;

  const TransactionEditDialog({super.key, required this.cashflow});

  static Future<void> show(BuildContext context, Cashflow cashflow) async {
    // Load categories before showing the dialog
    final categoryNotifier = context.read<CategoryNotifier>();
categoryNotifier.loadCategories();


    // Then show the dialog
    await showDialog(
      context: context,
      builder: (_) => TransactionEditDialog(cashflow: cashflow),
    );
  }

  @override
  State<TransactionEditDialog> createState() => _TransactionEditDialogState();
}

class _TransactionEditDialogState extends State<TransactionEditDialog> {
  String? selectedCategory;
  String? selectedProduct;
  double? amount;
  late DateTime selectedDate;

  final _formKey = GlobalKey<FormState>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.cashflow.categoryId;
    selectedProduct = widget.cashflow.productId;
    amount = widget.cashflow.amount.abs();
    selectedDate = widget.cashflow.date;

    // simulate loading to rebuild after categories load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cashflowNotifier = context.read<CashflowNotifier>();
    final categoryNotifier = context.watch<CategoryNotifier>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    Category? currentCategory = selectedCategory != null
        ? categoryNotifier.getCategoryById(selectedCategory!)
        : null;

    return AlertDialog(
      title: const Text('Edit Transaction'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryDropdown(
                  selectedCategory: selectedCategory,
                  onChanged: (value) => setState(() {
                    selectedCategory = value;
                    selectedProduct = null;
                  }),
                ),
                const SizedBox(height: 12),
                ProductDropdown(
                  categoryId: selectedCategory,
                  selectedProduct: selectedProduct,
                  onChanged: (value) => setState(() => selectedProduct = value),
                ),
                const SizedBox(height: 12),
                AmountInput(
                  initialAmount: amount, // ✅ fixed from before
                  onChanged: (value) => setState(() {
                    if (value != null) amount = value.abs();
                  }),
                ),
                const SizedBox(height: 12),
                DatePickerField(
                  selectedDate: selectedDate,
                  onDateChanged: (date) => setState(() => selectedDate = date),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('Cancel', style: TextStyle(color: theme.baseContent)),
  ),
  TextButton(
    onPressed: () async {
      // Show confirmation before deleting
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text(
              'Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.baseContent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.primaryContent,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        await cashflowNotifier.deleteCashflow(widget.cashflow.id);
        if (mounted) Navigator.pop(context);
      }
    },
    child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
  ),
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.primaryColor,
      foregroundColor: theme.primaryContent,
    ),
    onPressed: () async {
      if (!_formKey.currentState!.validate() ||
          selectedCategory == null ||
          amount == null) return;

      double finalAmount = amount!;
      if (currentCategory?.type == CategoryType.expense) {
        finalAmount = -finalAmount;
      }

      final updated = widget.cashflow.copyWith(
        categoryId: selectedCategory!,
        productId: selectedProduct,
        amount: finalAmount,
        date: selectedDate,
      );

      // Replace the old transaction with updated one
      await cashflowNotifier.deleteCashflow(widget.cashflow.id);
      await cashflowNotifier.addCashflow(updated);

      if (mounted) Navigator.pop(context);
    },
    child: const Text('Confirm'),
  ),
],

    );
  }
}
