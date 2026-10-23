import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/tenant_config.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final SupabaseClient _supabase;

  StreamSubscription<String>?
      _tokenRefreshSubscription;

  StreamSubscription<AuthState>?
      _authSubscription;

  PushNotificationService(this._supabase);

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  String get _platformName => _isIos ? 'ios' : 'android';

  /// On iOS the FCM token can only be fetched after the APNs token exists.
  /// Calling getToken() too early throws `apns-token-not-set`.
  Future<bool> _waitForApnsToken() async {
    for (var i = 0; i < 20; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<void> initialize() async {
    final settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (_isIos) {
      // iOS does not show notifications while the app is in the foreground
      // unless this is enabled.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (kDebugMode) {
      debugPrint(
        '🔔 Notification permission: '
        '${settings.authorizationStatus}',
      );
    }

    if (settings.authorizationStatus ==
        AuthorizationStatus.denied) {
      if (kDebugMode) {
        debugPrint(
          '🔕 Notification permission denied.',
        );
      }
      return;
    }

    // Register device immediately.
    // Login is NOT required for general notifications.
    await _registerDevice();

    // Listen for FCM token changes.
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(
      (newToken) async {
        if (kDebugMode) {
          debugPrint(
            '🔄 FCM TOKEN REFRESHED',
          );
        }

        await _registerDevice(
          token: newToken,
        );
      },
    );

    // If the user logs in later,
    // attach the existing device to the user.
    _authSubscription =
        _supabase.auth.onAuthStateChange.listen(
      (data) async {
        if (data.session != null) {
          if (kDebugMode) {
            debugPrint(
              '👤 User logged in → '
              'attaching device to user',
            );
          }

          await _registerDevice();
        }
      },
    );
  }

  Future<void> _registerDevice({
    String? token,
  }) async {
    try {
      if (_isIos && !await _waitForApnsToken()) {
        debugPrint(
          '⚠️ APNs token not available (check Push Notifications '
          'capability, APNs key in Firebase, and a real device).',
        );
        return;
      }

      final fcmToken =
          token ?? await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ FCM token is null/empty.',
          );
        }
        return;
      }

      final user =
          _supabase.auth.currentUser;

      if (kDebugMode) {
        debugPrint(
          '📱 Registering FCM device '
          '(authenticated: ${user != null})',
        );
      }

      await _supabase.rpc(
        'register_customer_push_device',
        params: {
          'p_restaurant_id':
              TenantConfig.restaurantId,
          'p_token': fcmToken,
          'p_platform': _platformName,
        },
      );

      if (kDebugMode) {
        if (user == null) {
          debugPrint(
            '✅ Device registered for '
            'general notifications.',
          );
        } else {
          debugPrint(
            '✅ Device registered and '
            'linked to user.',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '❌ Failed to register push device: $e',
      );
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
  }
}