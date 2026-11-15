import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:presence/app/controllers/notification_controller.dart';
import 'package:presence/app/controllers/presence_controller.dart';
import 'package:presence/firebase_options.dart';

class AttendanceBackgroundService {
  static final _service = FlutterBackgroundService();

  static Future<void> configure() async {
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'attendance_tracking',
            'Attendance tracking',
            description:
                'Visible while automatic attendance uses your location.',
            importance: Importance.low,
          ),
        );
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: attendanceWorker,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'attendance_tracking',
        initialNotificationTitle: 'ATEGO attendance',
        initialNotificationContent: 'Tracking attendance while signed in',
        foregroundServiceNotificationId: 4101,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  static Future<void> start(String uid) async {
    await stop();
    final ready = Completer<void>();
    final subscription = _service.on('ready').listen((_) {
      if (!ready.isCompleted) ready.complete();
    });
    try {
      if (!await _service.startService()) {
        throw StateError('Attendance service could not start.');
      }
      await ready.future.timeout(const Duration(seconds: 30));
      _service.invoke('begin', {'uid': uid});
    } catch (_) {
      _service.invoke('stop');
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }

  static Future<void> stop() async {
    if (!await _service.isRunning()) return;
    // Wait for the native service to stop before allowing a new user to start.
    _service.invoke('stop');
    for (var attempt = 0; attempt < 50; attempt++) {
      if (!await _service.isRunning()) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Attendance service did not stop.');
  }
}

@pragma('vm:entry-point')
Future<void> attendanceWorker(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  PresenceController? controller;
  var stopped = false;
  final subscriptions = <StreamSubscription<Map<String, dynamic>?>>[];
  subscriptions.add(
    service.on('stop').listen((_) async {
      stopped = true;
      controller?.onClose();
      controller = null;
      await service.stopSelf();
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (stopped) return;
    await NotificationController().initNotification(requestPermissions: false);
    if (stopped) return;
    subscriptions.add(
      service.on('begin').listen((event) {
        if (stopped || controller != null) return;
        final uid = event?['uid'];
        if (uid is! String) return;
        controller = PresenceController(
          backgroundWorker: true,
          expectedUid: uid,
          onInvalidUser: () {
            controller?.onClose();
            controller = null;
            stopped = true;
            service.stopSelf();
            for (final subscription in subscriptions) {
              subscription.cancel();
            }
          },
        );
        controller!.onInit();
      }),
    );
    service.invoke('ready');
  } catch (error) {
    debugPrint('Attendance worker initialization failed: $error');
    controller?.onClose();
    await service.stopSelf();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }
}
