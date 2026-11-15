import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:presence/app/widgets/toast/custom_toast.dart';
import 'package:presence/company_data.dart';

class HomeController extends GetxController {
  RxBool isLoading = false.obs;
  RxString officeDistance = "-".obs;
  final gpsStatus = 'Checking…'.obs;
  final permissionStatus = 'Checking…'.obs;
  final inOffice = Rxn<bool>();
  final lastLocationUpdate = Rxn<DateTime>();
  HomeController({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : auth = auth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  Timer? timer;
  String? _streamUid;
  String? _todayDocId;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _historyStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _todayStream;

  void _prepareStreams() {
    final uid = auth.currentUser!.uid;
    if (_streamUid == uid) return;
    _streamUid = uid;
    _userStream = null;
    _historyStream = null;
    _todayStream = null;
    _todayDocId = null;
  }

  void _clearLocation() {
    inOffice.value = null;
    officeDistance.value = '-';
    lastLocationUpdate.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    refreshLocation();
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (Get.currentRoute == Routes.HOME &&
          auth.currentUser?.emailVerified == true &&
          !isLoading.value) {
        refreshLocation();
      }
    });
  }

  Future<void> refreshLocation() async {
    final uid = auth.currentUser?.uid;
    if (isClosed ||
        isLoading.value ||
        uid == null ||
        auth.currentUser?.emailVerified != true)
      return;
    isLoading.value = true;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      if (isClosed || auth.currentUser?.uid != uid) return;
      gpsStatus.value = enabled ? 'Enabled' : 'Disabled';
      final granted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      permissionStatus.value = granted
          ? 'Granted'
          : permission == LocationPermission.deniedForever
          ? 'Blocked — enable in system settings'
          : 'Not granted — enable in system settings';
      if (!enabled || !granted) {
        _clearLocation();
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );
      if (isClosed || auth.currentUser?.uid != uid) return;
      final distance = Geolocator.distanceBetween(
        CompanyData.office['latitude'],
        CompanyData.office['longitude'],
        position.latitude,
        position.longitude,
      );
      officeDistance.value = distance >= 1000
          ? '${(distance / 1000).toStringAsFixed(1)} km'
          : '${distance.toStringAsFixed(0)} m';
      inOffice.value = distance <= 200;
      lastLocationUpdate.value = DateTime.now();
    } catch (_) {
      if (!isClosed && auth.currentUser?.uid == uid) {
        gpsStatus.value = 'Location check unavailable';
        _clearLocation();
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    timer?.cancel();
    super.onClose();
  }

  launchOfficeOnMap() {
    try {
      MapsLauncher.launchCoordinates(
        CompanyData.office['latitude'],
        CompanyData.office['longitude'],
      );
    } catch (e) {
      CustomToast.errorToast('Error', 'Error : ${e}');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser() {
    _prepareStreams();
    return _userStream ??= firestore
        .collection("employee")
        .doc(_streamUid!)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLastPresence() {
    _prepareStreams();
    return _historyStream ??= firestore
        .collection("employee")
        .doc(_streamUid!)
        .collection("presence")
        .orderBy("date", descending: true)
        .limit(3)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTodayPresence({
    DateTime? date,
  }) {
    _prepareStreams();
    final todayDocId = DateFormat.yMd()
        .format(date ?? DateTime.now())
        .replaceAll("/", "-");
    if (_todayDocId != todayDocId) {
      _todayDocId = todayDocId;
      _todayStream = null;
    }
    return _todayStream ??= firestore
        .collection("employee")
        .doc(_streamUid!)
        .collection("presence")
        .doc(todayDocId)
        .snapshots();
  }
}
