
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/controllers/notification_controller.dart';
import 'package:presence/app/widgets/dialog/custom_alert_dialog.dart';
import 'package:presence/app/widgets/toast/custom_toast.dart';
import 'package:presence/company_data.dart';
import 'dart:async';
import 'package:background_location/background_location.dart';

class PresenceController extends GetxController {
  RxBool isLoading = false.obs;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Timer? timer;
  Timer? intervalPresensi;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  @override
  void onDetached() async {
    intervalPresensi = Timer.periodic(Duration(seconds: 5), (timer) {
      presence();
    });
  }
  @override
  void onInit() async{
    super.onInit();
    WidgetsFlutterBinding.ensureInitialized();
    NotificationController().initNotification();
    intervalPresensi = Timer.periodic(Duration(seconds: 5), (timer) {
      presence();
    });
  }

  presence() async {
    isLoading.value = true;
    Map<String, dynamic> determinePosition = await _determinePosition();
    if (!determinePosition["error"]) {
      Position position = determinePosition["position"];
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String address = "${placemarks.first.street}, ${placemarks.first.subLocality}, ${placemarks.first.locality}";
      double distance = Geolocator.distanceBetween(CompanyData.office['latitude'], CompanyData.office['longitude'], position.latitude, position.longitude);

      // update position ( store to database )
      await updatePosition(position, address);
      // presence ( store to database )
      await processPresence(position, address, distance);
      isLoading.value = false;
    } else {
      isLoading.value = false;
      Get.snackbar("Terjadi kesalahan", determinePosition["message"]);
      print(determinePosition["error"]);
    }
  }

  firstPresence(
    CollectionReference<Map<String, dynamic>> presenceCollection,
    String todayDocId,
    Position position,
    String address,
    double distance,
    bool in_area,
    bool on_time,
  ) async {
    if (in_area == true && DateFormat('EEEE').format(DateTime.now()) != 'Sunday' &&  DateFormat('EEEE').format(DateTime.now()) != 'Saturday') {
      await presenceCollection.doc(todayDocId).set(
        {
          "date": DateTime.now().toIso8601String(),
          "masuk": {
            "date": DateTime.now().toIso8601String(),
            "latitude": position.latitude,
            "longitude": position.longitude,
            "address": address,
            "in_area": in_area,
            "distance": distance,
            "on_time": on_time,
          }
        },
      );
      Get.back();
      print('check in berhasil');
      CustomToast.successToast("Success", "Check-in successful");
    }
    else {
      //Get.back();
      print('check in gagal');
      // CustomToast.errorToast("Failed", "Check-in failed");
    }
  }



  checkinPresence(
    CollectionReference<Map<String, dynamic>> presenceCollection,
    String todayDocId,
    Position position,
    String address,
    double distance,
    bool in_area,
    bool on_time,
  ) async {
    if (in_area == true && DateFormat('EEEE').format(DateTime.now()) != 'Sunday' &&  DateFormat('EEEE').format(DateTime.now()) != 'Saturday') {
      await presenceCollection.doc(todayDocId).set(
        {
          "date": DateTime.now().toIso8601String(),
          "masuk": {
            "date": DateTime.now().toIso8601String(),
            "latitude": position.latitude,
            "longitude": position.longitude,
            "address": address,
            "in_area": in_area,
            "distance": distance,
            "on_time": on_time,
          }
        },
      );

      CustomToast.successToast("Success", "Check-in successful");
      NotificationController().showNotification(title: 'Check-in success!', body: 'Check-in successful on ' + DateTime.now().toIso8601String(), payload: 'test');
    }
    else {
      print('check in gagal');
    }
  }

  checkoutPresence(
    CollectionReference<Map<String, dynamic>> presenceCollection,
    String todayDocId,
    Position position,
    String address,
    double distance,
    bool in_area,
    bool on_time,
  ) async {
    await presenceCollection.doc(todayDocId).update(
      {
        "keluar": {
          "date": DateTime.now().toIso8601String(),
          "latitude": position.latitude,
          "longitude": position.longitude,
          "address": address,
          "in_area": in_area,
          "distance": distance,
          "on_time": on_time,
        }
      },
    );
    CustomToast.successToast("Success", "Check-out successful");
    NotificationController().showNotification(title: 'Check-out successful', body: 'Check-out successful on ' + DateTime.now().toIso8601String(), payload: 'test');
  }

  Future<void> processPresence(Position position, String address, double distance) async {
    String uid = auth.currentUser!.uid;
    String todayDocId = DateFormat.yMd().format(DateTime.now()).replaceAll("/", "-");

    CollectionReference<Map<String, dynamic>> presenceCollection = await firestore.collection("employee").doc(uid).collection("presence");
    QuerySnapshot<Map<String, dynamic>> snapshotPreference = await presenceCollection.get();

    bool in_area = false;
    if (distance <= 200) {
      in_area = true;
    }

    bool on_time = false;
    DateTime now = DateTime.now();
    if (now.isBefore(CompanyData.onTimeIn)) {
      on_time = true;
    }

    if (snapshotPreference.docs.length == 0) {
      firstPresence(presenceCollection, todayDocId, position, address, distance, in_area, on_time);
    } else {
      DocumentSnapshot<Map<String, dynamic>> todayDoc = await presenceCollection.doc(todayDocId).get();
      if (todayDoc.exists == true) {
        Map<String, dynamic>? dataPresenceToday = todayDoc.data();
        // case : already check in
        if (dataPresenceToday?["keluar"] != null) {
          // case : already check in and check out
          CustomToast.successToast("Success", "you already check in and check out");
        } else {
          if(!in_area || now.isAfter(DateTime(now.year, now.month, now.day, 23, 59))) {
            if (now.isAfter(CompanyData.onTimeOut) && now.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 00))) {
              on_time = true;
            } else {
              on_time = false;
            }
            checkoutPresence(
                presenceCollection, todayDocId, position, address, distance,
                in_area, on_time);
          }
        }
      } else {
        checkinPresence(presenceCollection, todayDocId, position, address, distance, in_area, on_time);
      }
    }
  }

  Future<void> updatePosition(Position position, String address) async {
    String uid = auth.currentUser!.uid;
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
    BackgroundLocation.startLocationService();

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        return {
          "message": "Tidak dapat mengakses karena Anda menolak permintaan akses lokasi",
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

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    return {
      "position": position,
      "message": "Berhasil mendapatkan posisi device",
      "error": false,
    };
  }

}
