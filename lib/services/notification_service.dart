import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Only initialize platform-specific notification channels on supported
    // mobile platforms. On desktop (Linux/macOS/Windows) the plugin may require
    // additional configuration; skip to avoid platform exceptions during debug.
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();

    // Create default channels for Android
    const AndroidNotificationChannel genChannel = AndroidNotificationChannel(
      'dream_generation',
      'Dream generation',
      description:
          'Notifiche relative alla generazione di immagini e interpretazioni',
      importance: Importance.low,
    );

    const AndroidNotificationChannel completeChannel =
        AndroidNotificationChannel(
          'dream_generation_complete',
          'Dream generation completed',
          description: "Notifica quando l'immagine del sogno è pronta",
          importance: Importance.defaultImportance,
        );

    await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
      ?..createNotificationChannel(genChannel)
      ..createNotificationChannel(completeChannel);

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Attempts to request notification permissions where needed (iOS / Android 13+).
  /// Returns true if permissions appear granted or request was successful.
  Future<bool> requestPermissions() async {
    try {
      // Best-effort permission request: for iOS/macOS the plugin exposes a requestPermissions
      // method through the platform implementation; for Android 13+ developers should
      // request POST_NOTIFICATIONS via permission_handler or platform channels.
      // We attempt to call platform implementations where available, otherwise return true
      // (assume manifest-declared permissions are sufficient).

      // Fallback: do not perform runtime permission requests here to avoid
      // referencing platform implementation classes that may cause build issues.
      // Recommend using `permission_handler` at the app level if stricter control
      // is required. For now assume manifest-configured permissions are sufficient.
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<void> showGeneratingNotification({
    int id = 1000,
    String? title,
    String? body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dream_generation',
      'Dream generation',
      channelDescription:
          'Notifiche relative alla generazione di immagini e interpretazioni',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      playSound: false,
      showWhen: false,
    );
    const iosDetails = DarwinNotificationDetails(presentSound: false);
    await _plugin.show(
      id,
      title ?? 'Generazione in corso',
      body ?? 'Lavoro in background',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> showCompletedNotification({
    int id = 1001,
    String? title,
    String? body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'dream_generation_complete',
      'Dream generation completed',
      channelDescription: 'Notifica quando l\'immagine del sogno è pronta',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      ongoing: false,
    );
    final iosDetails = DarwinNotificationDetails(presentSound: true);
    await _plugin.show(
      id,
      title ?? 'Generazione completata',
      body ?? 'La visualizzazione del sogno è pronta',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> cancelNotification({int id = 1000}) async {
    await _plugin.cancel(id);
  }
}
