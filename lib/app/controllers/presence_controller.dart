import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:presence/app/controllers/attendance_background_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/controllers/attendance_policy.dart';
import 'package:presence/app/controllers/notification_controller.dart';
import 'package:presence/app/widgets/toast/custom_toast.dart';
import 'package:presence/company_data.dart';

class PresenceController extends GetxController with WidgetsBindingObserver {
  PresenceController({
    this.backgroundWorker = false,
    this.expectedUid,
    this.onInvalidUser,
  });

  final bool backgroundWorker;
  final String? expectedUid;
  final VoidCallback? onInvalidUser;
  Future<void> _serviceChanges = Future<void>.value();
  bool get _usesAndroidService =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  RxBool isLoading = false.obs;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Timer? intervalPresensi;
  StreamSubscription<User?>? _authSubscription;
  int _session = 0;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    if (!backgroundWorker) WidgetsBinding.instance.addObserver(this);
    _authSubscription = auth.userChanges().listen((user) {
      _session++;
      intervalPresensi?.cancel();
      intervalPresensi = null;
      if (backgroundWorker) {
        if (user == null || !user.emailVerified || user.uid != expectedUid) {
          onInvalidUser?.call();
          return;
        }
      } else if (_usesAndroidService) {
        _queueServiceChange();
        return;
      }
      if (user != null && user.emailVerified) {
        intervalPresensi = Timer.periodic(const Duration(seconds: 5), (_) {
          presence();
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _usesAndroidService) {
      _queueServiceChange();
    }
  }

  void _queueServiceChange() {
    final session = _session;
    _serviceChanges = _serviceChanges
        .then((_) async {
          if (session != _session) return;
          await AttendanceBackgroundService.stop();
          final user = auth.currentUser;
          if (_closed || user == null || !user.emailVerified) return;
          if (WidgetsBinding.instance.lifecycleState !=
              AppLifecycleState.resumed) {
            return;
          }
          if (!await Geolocator.isLocationServiceEnabled()) return;
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always) {
            return;
          }
          if (!_isCurrentSession(user.uid, session) ||
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            return;
          }
          await AttendanceBackgroundService.start(user.uid);
          if (!_isCurrentSession(user.uid, session)) {
            await AttendanceBackgroundService.stop();
          }
        })
        .catchError((Object error) {
          debugPrint('Attendance service change failed: $error');
        });
  }

  @override
  void onClose() {
    _closed = true;
    _session++;
    intervalPresensi?.cancel();
    _authSubscription?.cancel();
    if (!backgroundWorker) {
      WidgetsBinding.instance.removeObserver(this);
      if (_usesAndroidService) _queueServiceChange();
    }
    super.onClose();
  }

  bool _isCurrentSession(String uid, int session) {
    return !_closed &&
        _session == session &&
        auth.currentUser?.uid == uid &&
        auth.currentUser?.emailVerified == true;
  }

  Future<void> presence() async {
    final user = auth.currentUser;
    if ((!backgroundWorker && _usesAndroidService) ||
        _closed ||
        isLoading.value ||
        user == null ||
        !user.emailVerified ||
        (backgroundWorker && user.uid != expectedUid)) {
      return;
    }
    final session = _session;
    isLoading.value = true;
    try {
      final result = await _determinePosition();
      if (!_isCurrentSession(user.uid, session)) return;
      if (result["error"] == true) {
        debugPrint(result["message"] as String);
        return;
      }
      final position = result["position"] as Position;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!_isCurrentSession(user.uid, session)) return;
      final address = placemarks.isEmpty
          ? ''
          : "${placemarks.first.street}, ${placemarks.first.subLocality}, ${placemarks.first.locality}";
      final distance = Geolocator.distanceBetween(
        CompanyData.office['latitude'],
        CompanyData.office['longitude'],
        position.latitude,
        position.longitude,
      );
      await updatePosition(position, address, uid: user.uid);
      if (!_isCurrentSession(user.uid, session)) return;
      await processPresence(
        position,
        address,
        distance,
        uid: user.uid,
        session: session,
      );
    } catch (error) {
      debugPrint('Attendance processing failed: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> processPresence(
    Position position,
    String address,
    double distance, {
    required String uid,
    required int session,
  }) async {
    final now = DateTime.now();
    // Preserve the document IDs and field names used by existing attendance views.
    final todayDocId = DateFormat.yMd().format(now).replaceAll("/", "-");
    final document = firestore
        .collection("employee")
        .doc(uid)
        .collection("presence")
        .doc(todayDocId);
    final inArea = distance <= 200;
    final action = await firestore.runTransaction<AttendanceAction>((
      transaction,
    ) async {
      final snapshot = await transaction.get(document);
      if (!_isCurrentSession(uid, session)) return AttendanceAction.none;
      final data = snapshot.data();
      final action = AttendancePolicy.action(
        now: now,
        inArea: inArea,
        hasCheckIn: data?["masuk"] != null,
        hasCheckOut: data?["keluar"] != null,
      );
      if (action == AttendanceAction.none) return action;
      final event = {
        "date": now.toIso8601String(),
        "latitude": position.latitude,
        "longitude": position.longitude,
        "address": address,
        "in_area": inArea,
        "distance": distance,
        "on_time": AttendancePolicy.isOnTime(now, action),
      };
      if (action == AttendanceAction.checkIn) {
        transaction.set(document, {
          "date": now.toIso8601String(),
          "masuk": event,
        }, SetOptions(merge: true));
      } else {
        transaction.update(document, {"keluar": event});
      }
      return action;
    });
    if (action == AttendanceAction.none || !_isCurrentSession(uid, session)) {
      return;
    }
    final label = action == AttendanceAction.checkIn ? 'Check-in' : 'Check-out';
    if (!backgroundWorker) {
      CustomToast.successToast("Success", "$label successful");
    }
    await NotificationController().showNotification(
      title: '$label successful',
      body: '$label successful on ${now.toIso8601String()}',
    );
  }

  Future<void> updatePosition(
    Position position,
    String address, {
    required String uid,
  }) async {
    await firestore.collection("employee").doc(uid).update({
      "position": {
        "latitude": position.latitude,
        "longitude": position.longitude,
      },
      "address": address,
    });
  }

  Future<Map<String, dynamic>> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (backgroundWorker) {
        return {"error": true, "message": "Location permission is required."};
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          "message": "Access failed because the location permission is denied.",
          "error": true,
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return {
        "message": "Location permissions are permanently denied, we cannot request permissions.",
        "error": true,
      };
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    return {
      "position": position,
      "message": "Successfully got the device's location.",
      "error": false,
    };
  }
}
