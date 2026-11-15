import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:presence/app/routes/app_pages.dart';

import '../../../widgets/toast/custom_toast.dart';

class ProfileController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser() async* {
    print("called");
    String uid = auth.currentUser!.uid;
    yield* firestore.collection("employee").doc(uid).snapshots();
  }

  bool _loggingOut = false;

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await auth.signOut();
      Get.offAllNamed(Routes.LOGIN);
    } catch (_) {
      CustomToast.errorToast('Unable to log out', 'Please try again.');
    } finally {
      _loggingOut = false;
    }
  }
}
