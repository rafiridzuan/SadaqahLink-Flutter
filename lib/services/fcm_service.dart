import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _deviceId;
  String? _currentToken;

  /// Sanitize device ID to be Firebase Realtime Database compatible
  /// Firebase paths cannot contain: . # $ [ ]
  String _sanitizeDeviceId(String deviceId) {
    return deviceId.replaceAll(RegExp(r'[.#$\[\]]'), '_');
  }

  /// Get unique device ID based on platform
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    String rawDeviceId;
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        rawDeviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        rawDeviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      } else {
        rawDeviceId = 'unknown_device';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      rawDeviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Sanitize the device ID to remove Firebase-incompatible characters
    _deviceId = _sanitizeDeviceId(rawDeviceId);
    debugPrint('Device ID: $rawDeviceId -> $_deviceId');

    return _deviceId!;
  }

  /// Request notification permissions (especially for iOS and Android 13+)
  Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      debugPrint('FCM Token: $_currentToken');
      return _currentToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firebase Realtime Database
  /// Structure: users/{uid}/fcmTokens/{deviceId} = token
  Future<void> saveTokenToDatabase(String uid) async {
    try {
      final deviceId = await getDeviceId();
      final token = await getToken();

      if (token == null) {
        debugPrint('No FCM token available to save');
        return;
      }

      final tokenRef = _database.ref('users/$uid/fcmTokens/$deviceId');
      await tokenRef.set(token);

      debugPrint('FCM token saved for device: $deviceId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token from database (called on logout)
  /// Removes ONLY the current device's token
  Future<void> removeTokenFromDatabase(String uid) async {
    try {
      final deviceId = await getDeviceId();
      final tokenRef = _database.ref('users/$uid/fcmTokens/$deviceId');
      await tokenRef.remove();

      debugPrint('FCM token removed for device: $deviceId');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Set up token refresh listener
  /// Automatically updates the token in database when it changes
  void setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      _currentToken = newToken;

      // Update token in database if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final deviceId = await getDeviceId();
        final tokenRef = _database.ref('users/${user.uid}/fcmTokens/$deviceId');
        await tokenRef.set(newToken);
        debugPrint('Refreshed FCM token saved for device: $deviceId');
      }
    });
  }

  /// Initialize FCM service after user logs in
  Future<void> initialize(String uid) async {
    try {
      // Request permissions
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Notification permission denied');
        return;
      }

      // Save token to database
      await saveTokenToDatabase(uid);

      // Set up token refresh listener
      setupTokenRefreshListener();
    } catch (e) {
      debugPrint('Error initializing FCM service: $e');
    }
  }

  /// Clean up on logout
  Future<void> cleanup(String uid) async {
    await removeTokenFromDatabase(uid);
  }
}
