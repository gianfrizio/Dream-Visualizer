import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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
