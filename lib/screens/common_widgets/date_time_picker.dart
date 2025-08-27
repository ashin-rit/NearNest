// lib/screens/common_widgets/date_time_picker.dart
import 'package:flutter/material.dart';

class DateTimePicker extends StatefulWidget {
  final ValueChanged<DateTime?> onDateTimeChanged;

  const DateTimePicker({super.key, required this.onDateTimeChanged});

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  DateTime? _selectedDateTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _selectTime(context, picked);
    }
  }

  Future<void> _selectTime(BuildContext context, DateTime date) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          picked.hour,
          picked.minute,
        );
      });
      widget.onDateTimeChanged(_selectedDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: const Text('Select Date & Time'),
            ),
          ],
        ),
        if (_selectedDateTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Selected: ${_selectedDateTime!.toLocal().toString().split(' ')[0]} at ${_selectedDateTime!.toLocal().toString().split(' ')[1].substring(0, 5)}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }
}