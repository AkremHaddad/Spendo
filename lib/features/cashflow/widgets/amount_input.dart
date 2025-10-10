import 'package:flutter/material.dart';

class AmountInput extends StatefulWidget {
  final Function(double?) onChanged;
  final double? initialAmount;

  const AmountInput({
    super.key,
    required this.onChanged,
    this.initialAmount,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Enter an amount' : null,
      onChanged: (value) {
        final parsed = double.tryParse(value);
        widget.onChanged(parsed);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
