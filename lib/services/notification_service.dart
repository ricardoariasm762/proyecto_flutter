import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  _handleNotificationAction(notificationResponse);
}

void _handleNotificationAction(NotificationResponse response) async {
  if (response.actionId == 'accept_request' && response.payload != null) {
    try {
      final parts = response.payload!.split(':');
      if (parts.length == 2 && parts[0] == 'request') {
        final requestId = parts[1];
        await Supabase.instance.client
            .from('ride_requests')
            .update({'status': 'accepted'})
            .eq('id', requestId);
      }
    } catch (_) {}
  }
}
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) => _handleNotificationAction(response),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'ridematch_channel',
      'RideMatch Notifications',
      channelDescription: 'Notifications for RideMatch app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'ridematch',
    );
  }

  Future<void> showRequestNotification({
    required int id,
    required String title,
    required String body,
    required String requestId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'request_channel',
      'Ride Requests',
      channelDescription: 'Notifications for new ride requests',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'accept_request',
          'Aceptar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'request:$requestId',
    );
  }
}
