// lib/screens/shop_service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/products_screen.dart';
import 'package:nearnest/screens/review_screen.dart';
import 'package:nearnest/services/favorites_service.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/screens/common_widgets/date_time_picker.dart';
import 'package:nearnest/models/service_package_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:nearnest/widgets/reviews_section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nearnest/services/one_signal_notification_sender.dart';
import 'package:firebase_auth/firebase_auth.dart';



class ShopServiceDetailScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const ShopServiceDetailScreen({
    super.key,
    required this.itemId,
    required this.data,
  });

  @override
  State<ShopServiceDetailScreen> createState() => _ShopServiceDetailScreenState();
}

class _ShopServiceDetailScreenState extends State<ShopServiceDetailScreen> with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  final BookingService _bookingService = BookingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

Future<void> _openMap(double latitude, double longitude, String customerName) async {
  if (latitude == 0.0 || longitude == 0.0) {
    _showSnackBar('Customer location not available', Colors.orange);
    return;
  }
  
  // Try Google Maps URL scheme first (better for mobile)
  final googleMapsUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
  
  // Fallback to web URL
  final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
  
  try {
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open map application', Colors.red);
    }
  } catch (e) {
    _showSnackBar('Error opening maps: $e', Colors.red);
  }
}

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showBookingDialog(ServicePackage package) async {
  DateTime? selectedDateTime;
  final _taskDescriptionController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Book ${package.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select your preferred date and time',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DateTimePicker(
                    onDateTimeChanged: (dateTime) {
                      selectedDateTime = dateTime;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _taskDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Task Description (optional)',
                      labelStyle: TextStyle(color: Color(0xFF718096)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    maxLines: 3,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedDateTime != null) {
                            // Get customer name for notification
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please log in to book a service.'),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                              return;
                            }

                            final userDoc = await _firestore
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            final customerName = userDoc.data()?['name'] ?? 'A customer';

                            // Create booking - NOW IT RETURNS THE BOOKING ID
                            final bookingId = await _bookingService.createBooking(
                              serviceProviderId: widget.itemId,
                              serviceName: package.name,
                              bookingTime: Timestamp.fromDate(selectedDateTime!),
                              taskDescription: _taskDescriptionController.text.isNotEmpty 
                                  ? _taskDescriptionController.text 
                                  : null,
                              servicePrice: package.price,
                              serviceDuration: package.durationInMinutes,
                            );

                            // 🔔 SEND NOTIFICATION TO SERVICE PROVIDER
                            if (bookingId != null) {
                              final formattedTime = DateFormat('MMM dd, yyyy at hh:mm a')
                                  .format(selectedDateTime!);
                              
                              await OneSignalNotificationSender.notifyServiceProviderOfNewBooking(
                                serviceProviderId: widget.itemId,
                                customerName: customerName,
                                serviceName: package.name,
                                bookingTime: formattedTime,
                                bookingId: bookingId,
                              );
                              
                              print('✅ Notification sent to service provider');
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Booking request sent successfully!'),
                                  backgroundColor: Colors.green[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Failed to create booking. Please try again.'),
                                  backgroundColor: Colors.red[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                            
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select a date and time.'),
                                backgroundColor: Colors.orange[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final String name = widget.data['name'] ?? 'N/A';
    final String description = widget.data['description'] ?? 'No description.';
    final String imageUrl = widget.data['imageUrl'] ?? '';
    final String role = widget.data['role'] ?? 'N/A';
    final String itemId = widget.itemId;
    
    // Location data
    final String streetAddress = widget.data['streetAddress'] ?? '';
    final String city = widget.data['city'] ?? '';
    final String state = widget.data['state'] ?? '';
    final String pincode = widget.data['pincode'] ?? '';
    final double latitude = (widget.data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double longitude = (widget.data['longitude'] as num?)?.toDouble() ?? 0.0;
    
    // Business hours (only for shops)
    final String businessHours = widget.data['business_hours'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2D3748)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: StreamBuilder<List<String>>(
                  stream: _favoritesService.getFavoriteItemIds(),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.hasData && snapshot.data!.contains(itemId);
                    return IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(isFavorite),
                          color: isFavorite ? Colors.red[500] : const Color(0xFF718096),
                        ),
                      ),
                      onPressed: () async {
                        if (isFavorite) {
                          await _favoritesService.removeFavorite(itemId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name removed from favorites.'),
                              backgroundColor: Colors.orange[600],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        } else {
                          await _favoritesService.addFavorite(itemId, name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name added to favorites.'),
                              backgroundColor: Colors.green[600],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'image_$itemId',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[100],
                            child: Icon(
                              role == 'Shop' ? Icons.store_rounded : Icons.business_center_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Icon(
                            role == 'Shop' ? Icons.store_rounded : Icons.business_center_rounded,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Rating Section
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore.collection('users').doc(itemId).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor.withOpacity(0.3),
                                      Theme.of(context).primaryColor,
                                    ],
                                  ),
                                ),
                                child: const LinearProgressIndicator(
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                                ),
                              );
                            }
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
                            final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Location Card
                                if (streetAddress.isNotEmpty || city.isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () {
                                      if (latitude != 0.0 && longitude != 0.0) {
                                        _openMap(latitude, longitude, name);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.1),
                                            Colors.cyan.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.blue,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Location',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2D3748),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  [
                                                    if (streetAddress.isNotEmpty) streetAddress,
                                                    if (city.isNotEmpty) city,
                                                    if (state.isNotEmpty) state,
                                                    if (pincode.isNotEmpty) pincode,
                                                  ].join(', '),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (latitude != 0.0 && longitude != 0.0)
                                            Icon(
                                              Icons.open_in_new_rounded,
                                              color: Colors.blue[400],
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                
                                // Business Hours (only for shops)
                                if (role == 'Shop' && businessHours.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.withOpacity(0.1),
                                          Colors.deepPurple.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.access_time_rounded,
                                            color: Colors.purple,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Business Hours',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2D3748),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                businessHours,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                
                                // Description
                                Text(
                                  'About',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Action Buttons
                                if (role == 'Shop') ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) =>
                                                ProductsScreen(shopId: itemId, shopName: name),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return SlideTransition(
                                                position: animation.drive(
                                                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                                      .chain(CurveTween(curve: Curves.easeInOut)),
                                                ),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                        shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.shopping_bag_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'View Products',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else if (role == 'Services') ...[
                                  // Service Packages Section
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Available Service Packages',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection('service_packages')
                                        .where('serviceProviderId', isEqualTo: itemId)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(32.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        );
                                      }
                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.inbox_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No packages available',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'This service provider hasn\'t listed any packages yet.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[500],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      final packages = snapshot.data!.docs
                                          .map((doc) => ServicePackage.fromMap(
                                              doc.data() as Map<String, dynamic>,
                                              id: doc.id))
                                          .toList();
                                      return ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: packages.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          final package = packages[index];
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.04),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Icon(
                                                          Icons.design_services_rounded,
                                                          color: Theme.of(context).primaryColor,
                                                          size: 24,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              package.name,
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                                color: Color(0xFF2D3748),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              '₹${package.price.toStringAsFixed(0)}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w600,
                                                                color: Theme.of(context).primaryColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    package.description,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      const Spacer(),
                                                      ElevatedButton(
                                                        onPressed: () => _showBookingDialog(package),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Theme.of(context).primaryColor,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 24, vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          elevation: 2,
                                                        ),
                                                        child: const Text(
                                                          'Book Now',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: 32),
                                // Reviews Section
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ReviewsSection(
                                    itemId: itemId,
                                    averageRating: averageRating,
                                    reviewCount: reviewCount,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}