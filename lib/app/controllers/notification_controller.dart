import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationController {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (
          int id,
          String? title,
          String? body,
          String? payload) async {}
    );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await notificationsPlugin.initialize(initializationSettings, onDidReceiveBackgroundNotificationResponse: (
        NotificationResponse notificationResponse) async{});
  }

  notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName', importance: Importance.max),
      iOS: DarwinNotificationDetails()
    );
  }

  Future showNotification({int id = 0, String? title, String? body, String? payload}) async {
    return notificationsPlugin.show(
      id, title, body, await _notificationDetails()
    );
  }

  static Future _notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel id',
        'channel name',
        channelDescription: 'channel description',
        importance: Importance.max,
        icon: "ic_launcher", //<-- Add this parameter
      ),
      //iOS: IOSNotificationDetails(),
    );
  }
}