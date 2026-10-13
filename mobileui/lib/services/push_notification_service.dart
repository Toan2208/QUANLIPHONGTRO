import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'landlord_messages',
    'Thông báo chủ trọ',
    description: 'Tin nhắn và thông báo mới từ chủ trọ',
    importance: Importance.high,
  );
  static int? _customerId;
  static String? _currentToken;

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);

    // Android không tự trình bày notification payload khi app đang foreground.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    _currentToken = await _messaging.getToken();
    if (_currentToken != null && kDebugMode) {
      // Token này dùng để đăng ký thiết bị với backend hoặc thử gửi từ Firebase Console.
      debugPrint('FCM device token: $_currentToken');
    }
    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      if (kDebugMode) {
        debugPrint('FCM device token refreshed: $newToken');
      }
      unawaited(_registerTokenForCurrentCustomer());
    });
  }

  static Future<void> registerCustomer(int customerId) async {
    _customerId = customerId;
    _currentToken ??= await _messaging.getToken();
    await _registerTokenForCurrentCustomer();
  }

  static Future<void> _registerTokenForCurrentCustomer() async {
    final customerId = _customerId;
    final token = _currentToken;
    if (customerId == null || token == null || token.isEmpty) return;

    final registered = await ApiService.registerDeviceToken(
      customerId: customerId,
      token: token,
    );
    if (!registered && kDebugMode) {
      debugPrint('Backend chưa đăng ký được FCM token cho khách #$customerId.');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    await _localNotifications.show(
      id:
          (message.messageId?.hashCode ??
              DateTime.now().millisecondsSinceEpoch) &
          0x7fffffff,
      title: title ?? 'Thông báo từ chủ trọ',
      body: body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> clearCustomer() async {
    _customerId = null;
  }
}
