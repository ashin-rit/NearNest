// lib/services/onesignal_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static bool _initialized = false;

  /// Initialize OneSignal (call once)
  static void initOneSignal({required String appId}) {
    if (_initialized) return;
    _initialized = true;

    // Optional: verbose logs (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize with App ID (per OneSignal docs)
    OneSignal.initialize(appId);

    // DO NOT force permission prompt on first open in production.
    // For testing you can prompt; in production prefer an in-app explain prompt first.
    OneSignal.Notifications.requestPermission(false);

    // Optional: handle notification opened/clicked
    OneSignal.Notifications.addClickListener((event) {
      // handle click, deep link, etc.
      // print('OneSignal click: ${event.notification.jsonRepresentation()}');
    });

    // Optional: handle in-app display
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // event.preventDefault(); // if you want to suppress system notification
      event.notification.display();
    });
  }

  /// Attempt to get the OneSignal player/user id (userId). Will retry a few times.
  static Future<String?> getPlayerId({
    int attempts = 5,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < attempts; i++) {
      try {
        final id = OneSignal.User.pushSubscription.id; // ✅ v5 way
        if (id != null && id.isNotEmpty) return id;
      } catch (e) {
        // ignore and retry
      }
      await Future.delayed(delay);
    }
    return null;
  }

  /// Save the playerId into the user's Firestore document under "playerId"
  static Future<void> savePlayerIdToFirestoreForUid(String uid) async {
    final playerId = await getPlayerId();
    if (playerId == null) {
      // couldn't get playerId
      return;
    }
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await docRef.set({'playerId': playerId}, SetOptions(merge: true));
  }

  /// Link OneSignal user to your app user (External ID).
  /// Call this after a successful login.
  static Future<void> setExternalId(String externalId) async {
    try {
      // recommended: use this to tie OneSignal record to your internal user id
      await OneSignal.login(externalId);
    } catch (e) {
      // ignore, but log in dev
      // print('OneSignal.login error: $e');
    }
  }

  /// Logout external id (optional on signout)
  static Future<void> logoutExternalId() => OneSignal.logout();
}
