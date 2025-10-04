import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/cashflowNotifier.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../data/models/cashflow.dart';
import '../../categories/data/models/category.dart';

import 'category_dropdown.dart';
import 'product_dropdown.dart';
import 'amount_input.dart';
import 'date_picker_field.dart';

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  String? selectedCategory;
  String? selectedProduct;
  double? amount;
  DateTime selectedDate = DateTime.now();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final cashflowNotifier = Provider.of<CashflowNotifier>(context, listen: false);
    final categoryNotifier = Provider.of<CategoryNotifier>(context, listen: false);

    Category? currentCategory = selectedCategory != null
        ? categoryNotifier.getCategoryById(selectedCategory!)
        : null;

    return AlertDialog(
      title: const Text('Add Transaction'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
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
                  onChanged: (value) => setState(() {
                    if (value != null) amount = value.abs(); // force positive
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                selectedCategory != null &&
                amount != null) {
              // Apply sign based on category type
              double finalAmount = amount!;
              if (currentCategory != null && currentCategory.type == CategoryType.expense) {
                finalAmount = -finalAmount;
              }

              final cashflow = Cashflow(
                id: '',
                categoryId: selectedCategory!,
                productId: selectedProduct,
                amount: finalAmount,
                date: selectedDate,
                userId: cashflowNotifier.userId,
              );

              cashflowNotifier.addCashflow(cashflow);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
