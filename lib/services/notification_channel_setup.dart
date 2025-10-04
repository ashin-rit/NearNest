import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationChannelSetup {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Only run on Android
      if (!Platform.isAndroid) {
        print('⚠️ Not on Android, skipping notification channel setup');
        return;
      }

      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );
      
      final initialized = await _notifications.initialize(settings);
      print('📱 Flutter Local Notifications initialized: $initialized');
      
      // Create the notification channel for Android 8.0+
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'nearNest_channel', // Must match OneSignal channel ID
        'NearNest Notifications',
        description: 'Channel for NearNest app notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final plugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (plugin != null) {
        await plugin.createNotificationChannel(channel);
        print('✅ Notification channel "nearNest_channel" created successfully');
        
        // Verify channel was created
        final channels = await plugin.getNotificationChannels();
        print('📋 Available channels: ${channels?.map((c) => c.id).toList()}');
      } else {
        print('❌ Could not resolve Android plugin');
      }
    } catch (e) {
      print('❌ Error creating notification channel: $e');
    }
  }
}