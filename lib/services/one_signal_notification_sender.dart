// lib/services/onesignal_notification_sender.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OneSignalNotificationSender {
  // IMPORTANT: In production, store this securely
  static const String _restApiKey = 'os_v2_app_wje5klby75bzri2m2fqnpuxxsuh5uv3r7eruhnmirin6thspbqyifkqezpzmsuivkhokzjzyg33ow6m62tq7q3zajttb2cgfi7un2lq';
  static const String _appId = 'b249d52c-38ff-4398-a34c-d160d7d2f795';
  static const String _apiUrl = 'https://onesignal.com/api/v1/notifications';

  /// Send notification to a specific user by their External ID (uid)
  static Future<bool> sendToExternalId({
    required String externalUserId,
    required String heading,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_external_user_ids': [externalUserId],
          'headings': {'en': heading},
          'contents': {'en': content},
          if (data != null) 'data': data,
          // Remove android_channel_id as discussed
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully to $externalUserId');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to a specific user by their Player ID
  static Future<bool> sendToPlayerId({
    required String playerId,
    required String heading,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_player_ids': [playerId],
          'headings': {'en': heading},
          'contents': {'en': content},
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully to player $playerId');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send notification for new order to shop owner
  static Future<void> notifyShopOwnerOfNewOrder({
    required String shopOwnerId,
    required String customerName,
    required int itemCount,
    required double totalAmount,
    required String orderId,
  }) async {
    await sendToExternalId(
      externalUserId: shopOwnerId,
      heading: '🛒 New Order Received!',
      content: '$customerName placed an order with $itemCount items (₹${totalAmount.toStringAsFixed(2)})',
      data: {
        'type': 'new_order',
        'orderId': orderId,
        'customerId': customerName,
      },
    );
  }

  /// Send notification for new service booking to service provider
  static Future<void> notifyServiceProviderOfNewBooking({
    required String serviceProviderId,
    required String customerName,
    required String serviceName,
    required String bookingTime,
    required String bookingId,
  }) async {
    await sendToExternalId(
      externalUserId: serviceProviderId,
      heading: '📅 New Booking Request!',
      content: '$customerName booked "$serviceName" for $bookingTime',
      data: {
        'type': 'new_booking',
        'bookingId': bookingId,
        'customerId': customerName,
      },
    );
  }

  /// Notify customer when their order status changes
  static Future<void> notifyCustomerOrderStatusChange({
    required String customerId,
    required String orderId,
    required String newStatus,
    required String shopName,
    String? remarks,
  }) async {
    String heading;
    String content;
    
    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        heading = '✅ Order Confirmed!';
        content = '$shopName has confirmed your order${remarks != null && remarks.isNotEmpty ? ": $remarks" : ""}';
        break;
      case 'processing':
        heading = '🔄 Order Processing';
        content = '$shopName is preparing your order';
        break;
      case 'ready for pickup':
        heading = '📦 Ready for Pickup!';
        content = 'Your order from $shopName is ready for pickup';
        break;
      case 'out for delivery':
        heading = '🚚 Out for Delivery';
        content = 'Your order from $shopName is on its way';
        break;
      case 'delivered':
        heading = '✅ Order Delivered!';
        content = 'Your order from $shopName has been delivered';
        break;
      case 'picked up':
        heading = '✅ Order Picked Up!';
        content = 'Your order from $shopName has been picked up successfully';
        break;
      case 'canceled':
      case 'cancelled':
        heading = '❌ Order Canceled';
        content = '$shopName has canceled your order${remarks != null && remarks.isNotEmpty ? ": $remarks" : ""}';
        break;
      default:
        heading = '📋 Order Update';
        content = 'Your order status has been updated to $newStatus';
    }

    await sendToExternalId(
      externalUserId: customerId,
      heading: heading,
      content: content,
      data: {
        'type': 'order_status_update',
        'orderId': orderId,
        'status': newStatus,
        'shopName': shopName,
      },
    );
  }

  /// Notify customer when their booking status changes
  static Future<void> notifyCustomerBookingStatusChange({
    required String customerId,
    required String bookingId,
    required String newStatus,
    required String serviceProviderName,
    required String serviceName,
    String? remarks,
  }) async {
    String heading;
    String content;
    
    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        heading = '✅ Booking Confirmed!';
        content = '$serviceProviderName has confirmed your booking for $serviceName${remarks != null && remarks.isNotEmpty ? ": $remarks" : ""}';
        break;
      case 'completed':
        heading = '✅ Service Completed!';
        content = 'Your $serviceName booking with $serviceProviderName has been completed';
        break;
      case 'canceled':
      case 'cancelled':
        heading = '❌ Booking Canceled';
        content = '$serviceProviderName has canceled your $serviceName booking${remarks != null && remarks.isNotEmpty ? ": $remarks" : ""}';
        break;
      default:
        heading = '📅 Booking Update';
        content = 'Your booking status has been updated to $newStatus';
    }

    await sendToExternalId(
      externalUserId: customerId,
      heading: heading,
      content: content,
      data: {
        'type': 'booking_status_update',
        'bookingId': bookingId,
        'status': newStatus,
        'serviceProviderName': serviceProviderName,
        'serviceName': serviceName,
      },
    );
  }
}