import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInput extends StatelessWidget {
  final ValueChanged<double?> onChanged;

  const AmountInput({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Amount'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // only digits and dot
      ],
      validator: (v) =>
          (v == null || double.tryParse(v) == null) ? 'Enter a valid number' : null,
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) {
          onChanged(parsed.abs()); // always positive
        } else {
          onChanged(null);
        }
      },
    );
  }
}
