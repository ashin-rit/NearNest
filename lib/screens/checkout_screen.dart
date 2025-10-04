import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:nearnest/services/inventory_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:nearnest/models/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/cart_item_model.dart';
import 'package:nearnest/services/one_signal_notification_sender.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, String> _selectedDeliveryOptions = {};
  final Map<String, bool> _isDeliveryAvailable = {};
  final Map<String, String> _shopNames = {};
  final InventoryService _inventoryService = InventoryService();
  
  bool _isPlacingOrders = false;
  bool _isLoadingShopData = true;
  bool _isValidatingStock = false;
  String? _streetAddress;
  String? _city;
  String? _state;
  String? _pincode;
  List<String> _stockErrors = [];
  List<String> _stockWarnings = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _initializeData();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _remarksControllers.values.forEach((controller) => controller.dispose());
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final cart = Provider.of<ShoppingCartService>(context, listen: false);
    final shopIds = cart.shopIds;

    if (shopIds.isEmpty) {
      setState(() {
        _isLoadingShopData = false;
      });
      return;
    }

    // Initialize controllers and default options for each shop
    for (String shopId in shopIds) {
      _remarksControllers[shopId] = TextEditingController();
      _selectedDeliveryOptions[shopId] = 'pickup'; // Default to pickup
    }

    await Future.wait([
      _fetchShopsData(shopIds),
      _fetchUserAddress(),
      _validateAllStock(),
    ]);

    setState(() {
      _isLoadingShopData = false;
    });
  }

  Future<void> _validateAllStock() async {
    setState(() {
      _isValidatingStock = true;
      _stockErrors.clear();
      _stockWarnings.clear();
    });

    final cart = Provider.of<ShoppingCartService>(context, listen: false);
    final validation = await _inventoryService.validateStock(cart.itemsList);

    setState(() {
      _stockErrors = List<String>.from(validation['errors']);
      _stockWarnings = List<String>.from(validation['warnings']);
      _isValidatingStock = false;
    });

    if (!validation['isValid']) {
      _showStockErrorDialog(validation);
    } else if (_stockWarnings.isNotEmpty) {
      _showStockWarningDialog();
    }
  }

  void _showStockErrorDialog(Map<String, dynamic> validation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Stock Unavailable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Some items in your cart are no longer available:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...validation['errors'].map<Widget>((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to cart to fix issues
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Cart'),
          ),
        ],
      ),
    );
  }

  void _showStockWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Stock Notice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please note:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._stockWarnings.map((warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchShopsData(List<String> shopIds) async {
    try {
      final shopDocs = await Future.wait(
        shopIds.map((shopId) => 
          FirebaseFirestore.instance.collection('users').doc(shopId).get()
        ),
      );

      for (int i = 0; i < shopDocs.length; i++) {
        final doc = shopDocs[i];
        final shopId = shopIds[i];
        
        if (doc.exists) {
          final data = doc.data();
          _shopNames[shopId] = data?['name'] ?? 'Unknown Shop';
          _isDeliveryAvailable[shopId] = data?['isDeliveryAvailable'] ?? false;
          
          // Set default delivery option based on availability
          if (_isDeliveryAvailable[shopId] == true) {
            _selectedDeliveryOptions[shopId] = 'delivery';
          }
        } else {
          _shopNames[shopId] = 'Unknown Shop';
          _isDeliveryAvailable[shopId] = false;
        }
      }
    } catch (e) {
      print('Error fetching shops data: $e');
    }
  }

  Future<void> _fetchUserAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _streetAddress = data?['streetAddress'] as String?;
          _city = data?['city'] as String?;
          _state = data?['state'] as String?;
          _pincode = data?['pincode'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching user address: $e');
    }
  }

Future<void> _placeAllOrders(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final cart = Provider.of<ShoppingCartService>(context, listen: false);

  if (user == null || cart.items.isEmpty) {
    _showErrorSnackBar('Cannot place empty orders. Please add items to your cart.');
    return;
  }

  setState(() {
    _isPlacingOrders = true;
  });

  try {
    // Final stock validation before placing orders
    final validation = await _inventoryService.validateStock(cart.itemsList);
    
    if (!validation['isValid']) {
      setState(() {
        _isPlacingOrders = false;
      });
      _showStockErrorDialog(validation);
      return;
    }

    // Get customer name for notification
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final customerName = userDoc.data()?['name'] ?? 'A customer';

    final itemsByShop = cart.itemsByShop;
    final List<String> successfulOrders = [];
    final List<String> failedOrders = [];

    // Create separate orders for each shop
    for (String shopId in itemsByShop.keys) {
      final shopItems = itemsByShop[shopId] ?? [];
      if (shopItems.isEmpty) continue;

      try {
        final shopTotal = cart.getTotalForShop(shopId);
        final isDelivery = _selectedDeliveryOptions[shopId] == 'delivery';
        final remarks = _remarksControllers[shopId]?.text ?? '';
        final shopName = _shopNames[shopId] ?? 'Unknown Shop';

        // Create the order
        final orderData = Order(
          id: '',
          userId: user.uid,
          items: shopItems,
          total: shopTotal,
          isDelivery: isDelivery,
          shopId: shopId,
          remarks: remarks,
          orderDate: Timestamp.now(),
          status: 'Pending',
        );

        // Add order to Firestore
        final orderRef = await FirebaseFirestore.instance
            .collection('orders')
            .add(orderData.toMap());

        // Reduce stock quantities
        final stockReduced = await _inventoryService.reduceStock(
          shopItems, 
          orderRef.id
        );

        if (stockReduced) {
          successfulOrders.add(shopName);
          
          // 🔔 SEND NOTIFICATION TO SHOP OWNER
          await OneSignalNotificationSender.notifyShopOwnerOfNewOrder(
            shopOwnerId: shopId,
            customerName: customerName,
            itemCount: shopItems.length,
            totalAmount: shopTotal,
            orderId: orderRef.id,
          );
          
          print('✅ Notification sent to shop: $shopName');
        } else {
          failedOrders.add(shopName);
        }

      } catch (e) {
        print('Error placing order for shop $shopId: $e');
        failedOrders.add(_shopNames[shopId] ?? 'Unknown Shop');
      }
    }

    if (successfulOrders.isNotEmpty) {
      // Clear cart after successful orders
      await cart.clearCart();
      
      String message;
      if (failedOrders.isEmpty) {
        message = successfulOrders.length == 1 
          ? 'Order placed successfully!'
          : '${successfulOrders.length} orders placed successfully!';
      } else {
        message = 'Some orders placed successfully. Please check your order history.';
      }
      
      _showSuccessSnackBar(message);
      Navigator.pop(context, true);
    } else {
      _showErrorSnackBar('Failed to place orders. Please try again.');
    }

  } catch (e) {
    print('Error placing orders: $e');
    _showErrorSnackBar('Failed to place orders. Please try again.');
  } finally {
    setState(() {
      _isPlacingOrders = false;
    });
  }
}

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context);
    final formattedAddress = _streetAddress != null && _city != null && _state != null && _pincode != null
        ? '$_streetAddress, $_city, $_state, $_pincode'
        : 'Address not found. Please update your profile.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: cart.items.isEmpty 
        ? _buildEmptyCart() 
        : _isLoadingShopData 
          ? _buildLoadingState()
          : _buildCheckoutContent(cart, formattedAddress),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        const SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF10B981),
                ),
                SizedBox(height: 16),
                Text(
                  'Validating stock and loading checkout...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverFillRemaining(
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add some products to proceed with checkout.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutContent(ShoppingCartService cart, String formattedAddress) {
    final itemsByShop = cart.itemsByShop;
    
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock validation status
                    if (_isValidatingStock) _buildValidatingStockBanner(),
                    if (_stockErrors.isNotEmpty) _buildStockErrorBanner(),
                    if (_stockWarnings.isNotEmpty && _stockErrors.isEmpty) _buildStockWarningBanner(),
                    
                    if (itemsByShop.length > 1)
                      _buildMultiShopNotice(itemsByShop.length),
                    const SizedBox(height: 20),
                    
                    // Build checkout sections for each shop
                    ...itemsByShop.entries.map((entry) {
                      final shopId = entry.key;
                      final shopItems = entry.value;
                      final shopName = _shopNames[shopId] ?? 'Unknown Shop';
                      
                      return Column(
                        children: [
                          _buildShopCheckoutSection(
                            shopId, 
                            shopName, 
                            shopItems, 
                            cart.getTotalForShop(shopId),
                            formattedAddress,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
                    _buildFinalOrderSummary(cart),
                    const SizedBox(height: 20),
                    _buildConfirmAllOrdersButton(cart),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidatingStockBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Validating product availability...',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Stock Issues Found',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._stockErrors.take(3).map((error) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $error',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          )).toList(),
          if (_stockErrors.length > 3)
            Text(
              'and ${_stockErrors.length - 3} more issues...',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildStockWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Stock Notices',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._stockWarnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $warning',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _validateAllStock,
            tooltip: 'Refresh Stock Status',
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981),
              Color(0xFF059669),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'Checkout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.payment_rounded,
                color: Colors.white24,
                size: 80,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiShopNotice(int shopCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Shop Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'You have items from $shopCount different shops. Each shop will receive a separate order.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCheckoutSection(String shopId, String shopName, List<CartItem> items, double shopTotal, String formattedAddress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shop Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6366F1),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${items.length} items • ₹${shopTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items Summary
                _buildShopItemsSummary(items),
                const SizedBox(height: 20),
                
                // Delivery Options
                _buildShopDeliveryOptions(shopId, shopName, formattedAddress),
                const SizedBox(height: 20),
                
                // Remarks
                _buildShopRemarksSection(shopId, shopName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItemsSummary(List<CartItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items in this order:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.shopping_bag_rounded, size: 20),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.shopping_bag_rounded, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildShopDeliveryOptions(String shopId, String shopName, String formattedAddress) {
    final isDeliveryAvailable = _isDeliveryAvailable[shopId] ?? false;
    final selectedOption = _selectedDeliveryOptions[shopId] ?? 'pickup';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery options for $shopName:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.store_rounded, size: 18, color: Color(0xFF8B5CF6)),
                    SizedBox(width: 8),
                    Text(
                      'Pickup',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                subtitle: const Text('Collect from store', style: TextStyle(fontSize: 12)),
                value: 'pickup',
                groupValue: selectedOption,
                activeColor: const Color(0xFF8B5CF6),
                onChanged: (value) {
                  setState(() {
                    _selectedDeliveryOptions[shopId] = value!;
                  });
                },
              ),
              if (isDeliveryAvailable)
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Icon(Icons.delivery_dining_rounded, size: 18, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text(
                        'Delivery',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  subtitle: const Text('Home delivery', style: TextStyle(fontSize: 12)),
                  value: 'delivery',
                  groupValue: selectedOption,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryOptions[shopId] = value!;
                    });
                  },
                ),
            ],
          ),
        ),
        if (selectedOption == 'delivery' && isDeliveryAvailable) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formattedAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShopRemarksSection(String shopId, String shopName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special instructions for $shopName:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _remarksControllers[shopId],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any special instructions...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalOrderSummary(ShoppingCartService cart) {
    final itemsByShop = cart.itemsByShop;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Final Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary by shop
            ...itemsByShop.entries.map((entry) {
              final shopId = entry.key;
              final shopItems = entry.value;
              final shopName = _shopNames[shopId] ?? 'Unknown Shop';
              final shopTotal = cart.getTotalForShop(shopId);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${shopItems.length} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${shopTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${cart.itemCount} items from ${itemsByShop.length} shop${itemsByShop.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${cart.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmAllOrdersButton(ShoppingCartService cart) {
    final orderCount = cart.shopIds.length;
    final hasStockErrors = _stockErrors.isNotEmpty;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasStockErrors ? [] : [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isPlacingOrders || hasStockErrors) ? null : () => _placeAllOrders(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasStockErrors ? Colors.grey.shade400 : const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isPlacingOrders
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Placing Orders...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : hasStockErrors
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Fix Stock Issues First',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        orderCount == 1 
                          ? 'Confirm Order • ₹${cart.totalAmount.toStringAsFixed(2)}'
                          : 'Place $orderCount Orders • ₹${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}