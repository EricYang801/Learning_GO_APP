// lib/services/notification_service.dart
// All identifiers in English; comments in 中文。

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 單例通知服務：負責初始化、權限、立即與排程通知
class NotificationService {
  // ===== Singleton =====
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;

  /// 初始化：權限 + 時區
  Future<void> init() async {
    if (_inited) return;

    // 1) iOS 初始化設定
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // 2) Android 初始化設定
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const init = InitializationSettings(iOS: ios, android: android);
    await _fln.initialize(init);

    // 3) iOS 16+ 臨時權限（若需要）
    if (Platform.isIOS) {
      await _fln
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Android 13+：不主動請求，交由 Manifest 控制

    // 5) time zone
    tz.initializeTimeZones();
    // 設定為系統時區
    tz.setLocalLocation(tz.local);

    _inited = true;
  }

  /// 立即顯示通知
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'general_channel', // channel id
        'General', // channel name
        channelDescription: 'General notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
    await _fln.show(id, title, body, details, payload: payload);
  }

  /// 指定時間排程（本地時區）
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when, // local time
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(when, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'schedule_channel',
        'Scheduled',
        channelDescription: 'Scheduled notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _fln.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload,
    );
  }

  /// 每天 00:00 觸發（使用 matchDateTimeComponents 保持每日重覆）
  Future<void> scheduleDailyMidnight({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0);
    if (!now.isBefore(next)) next = next.add(const Duration(days: 1));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel',
        'Daily',
        channelDescription: 'Daily checker',
        importance: Importance.low,
        priority: Priority.low,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _fln.zonedSchedule(
      id,
      title,
      body,
      next,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每天同一時間
      payload: payload,
    );
  }

  /// 取消指定 id
  Future<void> cancel(int id) => _fln.cancel(id);

  /// 取消全部
  Future<void> cancelAll() => _fln.cancelAll();
}
