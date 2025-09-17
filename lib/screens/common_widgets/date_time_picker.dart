// lib/screens/common_widgets/date_time_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatefulWidget {
  final Function(DateTime) onDateTimeChanged;
  final DateTime? initialDateTime;
  final String? dateLabel;
  final String? timeLabel;

  const DateTimePicker({
    Key? key,
    required this.onDateTimeChanged,
    this.initialDateTime,
    this.dateLabel = 'Select Date',
    this.timeLabel = 'Select Time',
  }) : super(key: key);

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _selectedDateTime;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _hasDateSelection = false;
  bool _hasTimeSelection = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateTime != null) {
      // Use provided initial date time (for editing existing bookings)
      _selectedDateTime = widget.initialDateTime!;
      _selectedDate = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day);
      _selectedTime = TimeOfDay.fromDateTime(_selectedDateTime);
      _hasDateSelection = true;
      _hasTimeSelection = true;
      
      // Notify parent of initial value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateTimeChanged(_selectedDateTime);
      });
    } else {
      // For new bookings, start with default values but don't show them
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      _selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      _hasDateSelection = false;
      _hasTimeSelection = false;
    }
  }

  @override
  void didUpdateWidget(DateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected date time if initial date time changed
    if (widget.initialDateTime != oldWidget.initialDateTime && widget.initialDateTime != null) {
      _selectedDateTime = widget.initialDateTime!;
      _selectedDate = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day);
      _selectedTime = TimeOfDay.fromDateTime(_selectedDateTime);
      widget.onDateTimeChanged(_selectedDateTime);
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF667EEA),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasDateSelection = true;
        // Only notify parent if both date and time are selected
        if (_hasTimeSelection) {
          _updateDateTime();
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF667EEA),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasTimeSelection = true;
        // Only notify parent if both date and time are selected
        if (_hasDateSelection) {
          _updateDateTime();
        }
      });
    }
  }

  void _updateDateTime() {
    _selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    widget.onDateTimeChanged(_selectedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCompleteSelection = (widget.initialDateTime != null) || (_hasDateSelection && _hasTimeSelection);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Picker
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dateLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasDateSelection ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDate) : 'Tap to select date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _hasDateSelection ? const Color(0xFF2D3748) : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Time Picker
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.timeLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasTimeSelection ? _selectedTime.format(context) : 'Tap to select time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _hasTimeSelection ? const Color(0xFF2D3748) : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        // Only show selected datetime summary if BOTH date and time are selected
        if (hasCompleteSelection) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: const Color(0xFF667EEA),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(_selectedDateTime)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}