// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send notification when a booking is created
exports.onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    try {
      const booking = snap.data();
      const serviceProviderId = booking.serviceProviderId;
      const userId = booking.userId;

      // Get service provider's FCM token
      const providerDoc = await admin.firestore()
        .collection('users')
        .doc(serviceProviderId)
        .get();

      if (!providerDoc.exists) {
        console.log('Service provider not found');
        return null;
      }

      const providerData = providerDoc.data();
      const fcmToken = providerData.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token found for service provider');
        return null;
      }

      // Get customer details
      const customerDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      const customerName = customerDoc.exists 
        ? customerDoc.data().name 
        : 'A customer';

      // Format booking time
      const bookingTime = booking.bookingTime.toDate();
      const dateStr = bookingTime.toLocaleDateString('en-IN', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
      });
      const timeStr = bookingTime.toLocaleTimeString('en-IN', {
        hour: '2-digit',
        minute: '2-digit'
      });

      // Create notification message
      const message = {
        notification: {
          title: 'New Service Booking',
          body: `${customerName} has booked ${booking.serviceName} from you at ${dateStr}, ${timeStr}`,
        },
        data: {
          type: 'booking',
          bookingId: context.params.bookingId,
          serviceName: booking.serviceName,
          customerName: customerName,
          bookingTime: bookingTime.toISOString(),
        },
        token: fcmToken,
      };

      // Send notification
      await admin.messaging().send(message);
      console.log('Booking notification sent successfully');

      // Save notification to provider's subcollection
      await admin.firestore()
        .collection('users')
        .doc(serviceProviderId)
        .collection('notifications')
        .add({
          title: message.notification.title,
          body: message.notification.body,
          data: message.data,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });

      return null;
    } catch (error) {
      console.error('Error sending booking notification:', error);
      return null;
    }
  });

// Send notification when an order is created
exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    try {
      const order = snap.data();
      const shopId = order.shopId;
      const userId = order.userId;

      // Get shop's FCM token
      const shopDoc = await admin.firestore()
        .collection('users')
        .doc(shopId)
        .get();

      if (!shopDoc.exists) {
        console.log('Shop not found');
        return null;
      }

      const shopData = shopDoc.data();
      const fcmToken = shopData.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token found for shop');
        return null;
      }

      // Get customer details
      const customerDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      const customerName = customerDoc.exists 
        ? customerDoc.data().name 
        : 'A customer';

      // Get product names from items
      const items = order.items || [];
      const productNames = items.slice(0, 2).map(item => item.name).join(', ');
      const moreItems = items.length > 2 ? ` and ${items.length - 2} more` : '';
      
      // Delivery or pickup
      const deliveryType = order.isDelivery ? 'Delivery' : 'Pickup';

      // Create notification message
      const message = {
        notification: {
          title: 'New Order Received',
          body: `${customerName} ordered ${productNames}${moreItems} (${deliveryType}) - ₹${order.total.toFixed(2)}`,
        },
        data: {
          type: 'order',
          orderId: context.params.orderId,
          customerName: customerName,
          deliveryType: deliveryType,
          total: order.total.toString(),
          itemCount: items.length.toString(),
        },
        token: fcmToken,
      };

      // Send notification
      await admin.messaging().send(message);
      console.log('Order notification sent successfully');

      // Save notification to shop's subcollection
      await admin.firestore()
        .collection('users')
        .doc(shopId)
        .collection('notifications')
        .add({
          title: message.notification.title,
          body: message.notification.body,
          data: message.data,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });

      return null;
    } catch (error) {
      console.error('Error sending order notification:', error);
      return null;
    }
  });

// Optional: Send notification when booking status changes
exports.onBookingStatusUpdate = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const oldData = change.before.data();

      // Check if status changed
      if (newData.status === oldData.status) {
        return null;
      }

      const userId = newData.userId;

      // Get customer's FCM token
      const customerDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!customerDoc.exists) {
        console.log('Customer not found');
        return null;
      }

      const customerData = customerDoc.data();
      const fcmToken = customerData.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token found for customer');
        return null;
      }

      // Create notification based on status
      let title = 'Booking Update';
      let body = '';

      switch (newData.status) {
        case 'Accepted':
          body = `Your booking for ${newData.serviceName} has been accepted!`;
          break;
        case 'Completed':
          body = `Your booking for ${newData.serviceName} has been completed.`;
          break;
        case 'Cancelled':
          body = `Your booking for ${newData.serviceName} has been cancelled.`;
          break;
        default:
          body = `Your booking for ${newData.serviceName} status updated to ${newData.status}`;
      }

      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: 'booking_update',
          bookingId: context.params.bookingId,
          status: newData.status,
          serviceName: newData.serviceName,
        },
        token: fcmToken,
      };

      // Send notification
      await admin.messaging().send(message);
      console.log('Booking status notification sent successfully');

      // Save notification to customer's subcollection
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          title: message.notification.title,
          body: message.notification.body,
          data: message.data,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });

      return null;
    } catch (error) {
      console.error('Error sending booking status notification:', error);
      return null;
    }
  });

// Optional: Send notification when order status changes
exports.onOrderStatusUpdate = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const oldData = change.before.data();

      // Check if status changed
      if (newData.status === oldData.status) {
        return null;
      }

      const userId = newData.userId;

      // Get customer's FCM token
      const customerDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!customerDoc.exists) {
        console.log('Customer not found');
        return null;
      }

      const customerData = customerDoc.data();
      const fcmToken = customerData.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token found for customer');
        return null;
      }

      // Create notification based on status
      let title = 'Order Update';
      let body = '';

      switch (newData.status) {
        case 'Accepted':
          body = `Your order has been accepted and is being prepared!`;
          break;
        case 'Ready':
          body = newData.isDelivery 
            ? 'Your order is ready for delivery!'
            : 'Your order is ready for pickup!';
          break;
        case 'Completed':
          body = 'Your order has been completed. Thank you!';
          break;
        case 'Cancelled':
          body = 'Your order has been cancelled.';
          break;
        default:
          body = `Your order status updated to ${newData.status}`;
      }

      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: 'order_update',
          orderId: context.params.orderId,
          status: newData.status,
          total: newData.total.toString(),
        },
        token: fcmToken,
      };

      // Send notification
      await admin.messaging().send(message);
      console.log('Order status notification sent successfully');

      // Save notification to customer's subcollection
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          title: message.notification.title,
          body: message.notification.body,
          data: message.data,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });

      return null;
    } catch (error) {
      console.error('Error sending order status notification:', error);
      return null;
    }
  });