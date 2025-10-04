import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DatePickerField({super.key, required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onDateChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Date'),
        child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
      ),
    );
  }
}
