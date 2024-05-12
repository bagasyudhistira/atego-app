import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AllUsersPresenceController extends GetxController {
  DateTime? start;
  DateTime end = DateTime.now();
  String selectedUser2 = '-';
  var displayUser = ''.obs;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<QuerySnapshot<Map<String, dynamic>>> getAllUsersPresence() async {
    String uid = selectedUser2;
    if (start == null) {
      QuerySnapshot<Map<String, dynamic>> query = await firestore
          .collection("employee")
          .doc(uid)
          .collection("presence")
          .where("date", isLessThan: end.toIso8601String())
          .orderBy(
        "date",
        descending: true,
      )
          .get();

      return query;
    } else {
      QuerySnapshot<Map<String, dynamic>> query = await firestore
          .collection("employee")
          .doc(uid)
          .collection("presence")
          .where("date", isGreaterThan: start!.toIso8601String())
          .where("date", isLessThan: end.add(Duration(days: 1)).toIso8601String())
          .orderBy(
        "date",
        descending: true,
      )
          .get();

      return query;
    }
  }

  void pickDate(DateTime pickStart, DateTime pickEnd) {
    start = pickStart;
    end = pickEnd;

    update();
    Get.back();
  }

  void UserSearch(String userID) {
    selectedUser2 = userID;
    update();
  }
}