import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ShopProfileEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> initialData;

  const ShopProfileEditScreen({
    Key? key,
    required this.userId,
    required this.initialData,
  }) : super(key: key);

  @override
  _ShopProfileEditScreenState createState() => _ShopProfileEditScreenState();
}

class _ShopProfileEditScreenState extends State<ShopProfileEditScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  bool _isDeliveryAvailable = false;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  double? _latitude;
  double? _longitude;
  
  // Business hours with individual days
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Map<String, bool> _selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _initializeData();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _nameController.text = widget.initialData['name'] ?? '';
    _emailController.text = widget.initialData['email'] ?? '';
    _phoneController.text = widget.initialData['phone'] ?? '';
    _streetAddressController.text = widget.initialData['streetAddress'] ?? '';
    _cityController.text = widget.initialData['city'] ?? '';
    _stateController.text = widget.initialData['state'] ?? '';
    _pincodeController.text = widget.initialData['pincode'] ?? '';
    _descriptionController.text = widget.initialData['description'] ?? '';
    _categoryController.text = widget.initialData['category'] ?? '';
    _isDeliveryAvailable = widget.initialData['isDeliveryAvailable'] ?? false;
    
    // Parse business hours if exists
    String businessHours = widget.initialData['business_hours'] ?? '';
    if (businessHours.isNotEmpty) {
      _parseBusinessHours(businessHours);
    }
    
    final GeoPoint? location = widget.initialData['location'] as GeoPoint?;
    if (location != null) {
      _latitude = location.latitude;
      _longitude = location.longitude;
    } else {
      _latitude = widget.initialData['latitude'];
      _longitude = widget.initialData['longitude'];
    }
  }

  void _parseBusinessHours(String businessHours) {
    try {
      if (businessHours.contains(':') && businessHours.contains('-')) {
        List<String> parts = businessHours.split(':');
        if (parts.length >= 2) {
          String daysPart = parts[0].trim();
          String timePart = parts[1].trim();
          
          // Parse days
          if (daysPart.contains('Monday') && daysPart.contains('Friday')) {
            for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
              _selectedDays[day] = true;
            }
          } else if (daysPart.contains('Monday') && daysPart.contains('Saturday')) {
            for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']) {
              _selectedDays[day] = true;
            }
          } else if (daysPart.toLowerCase().contains('all')) {
            _selectedDays.updateAll((key, value) => true);
          } else if (daysPart.toLowerCase().contains('weekend')) {
            _selectedDays['Saturday'] = true;
            _selectedDays['Sunday'] = true;
          } else {
            for (var day in daysPart.split(',')) {
              String cleanDay = day.trim();
              if (_selectedDays.containsKey(cleanDay)) {
                _selectedDays[cleanDay] = true;
              }
            }
          }
          
          // Parse times
          if (timePart.contains('-')) {
            List<String> times = timePart.split('-');
            if (times.length == 2) {
              _startTime = _parseTimeString(times[0].trim());
              _endTime = _parseTimeString(times[1].trim());
            }
          }
        }
      }
    } catch (e) {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 21, minute: 0);
      _selectedDays['Monday'] = true;
      _selectedDays['Saturday'] = true;
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      timeStr = timeStr.replaceAll(' ', '');
      bool isPM = timeStr.toLowerCase().contains('pm');
      bool isAM = timeStr.toLowerCase().contains('am');
      
      String cleanTime = timeStr.replaceAll(RegExp(r'[apmAMP\s]'), '');
      List<String> parts = cleanTime.split(':');
      
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        if (isPM && hour != 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _formatBusinessHours() {
    List<String> selectedDaysList = _selectedDays.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (selectedDaysList.isEmpty || _startTime == null || _endTime == null) {
      return '';
    }
    
    String daysString = _formatDaysList(selectedDaysList);
    return '$daysString: ${_startTime!.format(context)} - ${_endTime!.format(context)}';
  }

  String _formatDaysList(List<String> days) {
    if (days.length == 7) {
      return 'All Days';
    } else if (days.length == 5 && 
               days.contains('Monday') && 
               days.contains('Tuesday') && 
               days.contains('Wednesday') && 
               days.contains('Thursday') && 
               days.contains('Friday')) {
      return 'Monday - Friday';
    } else if (days.length == 6 && 
               days.contains('Monday') && 
               !days.contains('Sunday')) {
      return 'Monday - Saturday';
    } else if (days.length == 2 && 
               days.contains('Saturday') && 
               days.contains('Sunday')) {
      return 'Weekends Only';
    } else {
      return days.join(', ');
    }
  }

  String? _validateBusinessHours() {
    bool anyDaySelected = _selectedDays.values.any((selected) => selected);
    if (!anyDaySelected) {
      return 'Please select at least one working day';
    }
    
    if (_startTime == null || _endTime == null) {
      return 'Please set both opening and closing times';
    }
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    if (endMinutes <= startMinutes) {
      return 'Closing time must be after opening time';
    }
    
    if (endMinutes - startMinutes < 60) {
      return 'Business hours must be at least 1 hour';
    }
    
    return null;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 21, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: const Color(0xFF6366F1),
              dayPeriodTextColor: const Color(0xFF6366F1),
              dialHandColor: const Color(0xFF6366F1),
              dialBackgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      
      String? error = _validateBusinessHours();
      if (error != null && _startTime != null && _endTime != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _toggleAllDays(bool value) {
    setState(() {
      _selectedDays.updateAll((key, _) => value);
    });
  }

  void _toggleWeekdays() {
    setState(() {
      for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
        _selectedDays[day] = true;
      }
      _selectedDays['Saturday'] = false;
      _selectedDays['Sunday'] = false;
    });
  }

  void _toggleWeekends() {
    setState(() {
      _selectedDays['Saturday'] = true;
      _selectedDays['Sunday'] = true;
      for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
        _selectedDays[day] = false;
      }
    });
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      Position position = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _streetAddressController.text = place.street ?? '';
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _pincodeController.text = place.postalCode ?? '';
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location updated successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    String? businessHoursError = _validateBusinessHours();
    if (businessHoursError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(businessHoursError)),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'streetAddress': _streetAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'business_hours': _formatBusinessHours(),
        'isDeliveryAvailable': _isDeliveryAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final fullAddress = '${_streetAddressController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()}, ${_pincodeController.text.trim()}';
      List<Location> locations = await locationFromAddress(fullAddress);
      
      if (locations.isNotEmpty) {
        _latitude = locations.first.latitude;
        _longitude = locations.first.longitude;
        dataToUpdate['location'] = GeoPoint(_latitude!, _longitude!);
        dataToUpdate['latitude'] = _latitude;
        dataToUpdate['longitude'] = _longitude;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid address. Please enter a valid location.'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      await _authService.updateUserData(widget.userId, dataToUpdate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Shop Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.save_rounded,
                  color: Color(0xFF10B981),
                ),
                onPressed: _updateProfile,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOutCubic,
                )),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 32),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      _buildBusinessDetailsSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Updating your profile...',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your business information up to date',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      'Basic Information',
      Icons.info_rounded,
      const Color(0xFF6366F1),
      [
        _buildTextField(_nameController, 'Shop Name', Icons.store_rounded),
        _buildTextField(_emailController, 'Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
        _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      'Location Details',
      Icons.location_on_rounded,
      const Color(0xFF10B981),
      [
        _buildTextField(_streetAddressController, 'Street Address', Icons.home_rounded),
        Row(
          children: [
            Expanded(child: _buildTextField(_cityController, 'City', Icons.location_city_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_stateController, 'State', Icons.map_rounded)),
          ],
        ),
        _buildTextField(_pincodeController, 'Pincode', Icons.pin_drop_rounded, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildLocationButton(),
      ],
    );
  }

  Widget _buildBusinessDetailsSection() {
    return _buildSection(
      'Business Details',
      Icons.business_rounded,
      const Color(0xFF3B82F6),
      [
        _buildTextField(_descriptionController, 'Description', Icons.description_rounded, maxLines: 3),
        _buildTextField(_categoryController, 'Category', Icons.category_rounded),
        const SizedBox(height: 16),
        _buildBusinessHoursSection(),
        const SizedBox(height: 16),
        _buildDeliverySwitch(),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Business Hours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Quick select buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickSelectButton(
                  'Weekdays',
                  Icons.work_outline_rounded,
                  _toggleWeekdays,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickSelectButton(
                  'Weekends',
                  Icons.weekend_rounded,
                  _toggleWeekends,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickSelectButton(
                  'All Days',
                  Icons.calendar_month_rounded,
                  () => _toggleAllDays(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Individual day checkboxes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Select Open Days',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._selectedDays.keys.map((day) => _buildDayCheckbox(day)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Time selection
          Text(
            'Operating Hours',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector('Opening Time', _startTime, true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
              Expanded(
                child: _buildTimeSelector('Closing Time', _endTime, false),
              ),
            ],
          ),
          
          // Hours summary
          if (_startTime != null && _endTime != null) ...[
            const SizedBox(height: 16),
            _buildHoursSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCheckbox(String day) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDays[day] = !_selectedDays[day]!;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _selectedDays[day]! 
                    ? const Color(0xFF6366F1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _selectedDays[day]! 
                      ? const Color(0xFF6366F1) 
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: _selectedDays[day]!
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _selectedDays[day]! 
                      ? FontWeight.w600 
                      : FontWeight.w500,
                  color: _selectedDays[day]! 
                      ? const Color(0xFF1F2937) 
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSummary() {
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final totalMinutes = endMinutes - startMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    bool isValid = totalMinutes > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [const Color(0xFF6366F1).withOpacity(0.1), const Color(0xFF8B5CF6).withOpacity(0.1)]
              : [Colors.red.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid 
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isValid ? const Color(0xFF6366F1) : Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isValid ? 'Schedule Summary' : 'Invalid Time Selection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isValid ? const Color(0xFF6366F1) : Colors.red.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (isValid) ...[
            const SizedBox(height: 12),
            Text(
              _formatBusinessHours(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Total: $hours hour${hours != 1 ? 's' : ''}${minutes > 0 ? ' $minutes min' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Closing time must be after opening time',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? selectedTime, bool isStartTime) {
    return InkWell(
      onTap: () => _selectTime(context, isStartTime),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedTime != null 
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : Colors.grey.shade300,
            width: selectedTime != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: selectedTime != null 
                      ? const Color(0xFF6366F1) 
                      : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  selectedTime?.format(context) ?? '--:--',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selectedTime != null 
                        ? const Color(0xFF1F2937) 
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: _isLocationLoading ? null : _updateLocation,
        icon: _isLocationLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location_rounded, size: 20),
        label: Text(
          _isLocationLoading ? 'Getting Location...' : 'Update to Current Location',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Enable delivery for your customers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDeliveryAvailable,
            onChanged: (bool value) {
              setState(() {
                _isDeliveryAvailable = value;
              });
            },
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _updateProfile,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded, size: 24),
        label: Text(
          _isLoading ? 'Saving Changes...' : 'Save Changes',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}