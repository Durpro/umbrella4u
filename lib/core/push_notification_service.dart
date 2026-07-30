import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/umbrella_repository.dart';

/// Manages the phone-only part of push notifications. Notification delivery
/// remains opt-in: this service never displays the OS permission prompt until
/// the member turns the setting on.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _androidChannel = AndroidNotificationChannel(
    'haven_support_updates',
    'Haven support updates',
    description: 'Private updates about your Haven support activity.',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  UmbrellaRepository? _repository;
  bool _initialized = false;
  bool _enabledForCurrentUser = false;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(_handleTokenRefresh);
    _initialized = true;
  }

  /// Registers a token only after the person deliberately enables pushes in
  /// Settings. It never asks for permission during launch or sign-in.
  Future<bool> requestAndEnable(UmbrellaRepository repository) async {
    if (!isSupported || !repository.isLive || repository.currentUser == null) {
      return false;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!_hasPermission(settings)) return false;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;

    _repository = repository;
    _enabledForCurrentUser = true;
    await repository.upsertPushToken(token: token, platform: _platform);
    return true;
  }

  /// Refreshes an already opted-in device after sign-in or app launch without
  /// prompting again. A user who turned pushes off stays opted out.
  Future<void> syncSignedInUser(UmbrellaRepository repository) async {
    if (!isSupported || !repository.isLive || repository.currentUser == null) {
      return;
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (!_hasPermission(settings)) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    _repository = repository;
    _enabledForCurrentUser = await repository.isPushTokenEnabled(token);
    if (_enabledForCurrentUser) {
      await repository.upsertPushToken(token: token, platform: _platform);
    }
  }

  Future<bool> isEnabledForCurrentUser(UmbrellaRepository repository) async {
    if (!isSupported || !repository.isLive || repository.currentUser == null) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;
    return repository.isPushTokenEnabled(token);
  }

  Future<void> disableForCurrentUser(UmbrellaRepository repository) async {
    if (!isSupported || !repository.isLive || repository.currentUser == null) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await repository.setPushTokenEnabled(token: token, enabled: false);
    }
    _enabledForCurrentUser = false;
  }

  Future<void> _handleTokenRefresh(String token) async {
    final repository = _repository;
    if (!_enabledForCurrentUser || repository == null || !repository.isLive) {
      return;
    }
    try {
      await repository.upsertPushToken(token: token, platform: _platform);
    } catch (_) {
      // The next foreground launch retries the registration. A token refresh
      // should never interfere with the rest of the app.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'Umbrella4U',
      body: notification.body ?? 'You have a new support update.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'haven_support_updates',
          'Haven support updates',
          channelDescription:
              'Private updates about your Haven support activity.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  bool _hasPermission(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
