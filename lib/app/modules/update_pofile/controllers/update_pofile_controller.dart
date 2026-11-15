import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as s;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class UpdatePofileController extends GetxController {
  RxBool isLoading = false.obs;
  TextEditingController employeeidC = TextEditingController();
  TextEditingController nameC = TextEditingController();
  TextEditingController emailC = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  s.FirebaseStorage storage = s.FirebaseStorage.instance;

  final ImagePicker picker = ImagePicker();
  final isPickingImage = false.obs;
  XFile? image;

  @override
  void onInit() {
    super.onInit();
    final user = Get.arguments as Map<String, dynamic>;
    employeeidC.text = user['employee_id'] as String? ?? '';
    nameC.text = user['name'] as String? ?? '';
    emailC.text = user['email'] as String? ?? '';
  }

  @override
  void onClose() {
    employeeidC.dispose();
    nameC.dispose();
    emailC.dispose();
    super.onClose();
  }

  Future<void> updateProfile(BuildContext context) async {
    if (isLoading.value || isPickingImage.value) return;
    final messenger = ScaffoldMessenger.of(context);
    final user = auth.currentUser;
    final name = nameC.text.trim();
    if (user == null || !user.emailVerified) {
      _message(messenger, 'Sign in with a verified account first.');
      return;
    }
    if (name.isEmpty || name.length > 200) {
      _message(messenger, 'Enter a name between 1 and 200 characters.');
      return;
    }
    isLoading.value = true;
    try {
      final data = <String, dynamic>{'name': name};
      final selectedImage = image;
      if (selectedImage != null) {
        final file = File(selectedImage.path);
        if (await file.length() > 5 * 1024 * 1024) {
          _message(messenger, 'Choose an image smaller than 5 MB.');
          return;
        }
        final ext = selectedImage.name.split('.').last.toLowerCase();
        final contentType = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => null,
        };
        if (contentType == null) {
          _message(messenger, 'Choose a JPEG, PNG, or WebP image.');
          return;
        }
        final ref = storage.ref('${user.uid}/avatar.$ext');
        await ref.putFile(file, s.SettableMetadata(contentType: contentType));
        data['avatar'] = await ref.getDownloadURL();
      }
      if (auth.currentUser?.uid != user.uid) return;
      await firestore.collection('employee').doc(user.uid).update(data);
      image = null;
      Get.back();
      _message(messenger, 'Profile updated.');
    } on s.FirebaseException catch (error) {
      final message = switch (error.code) {
        'object-not-found' || 'bucket-not-found' || 'project-not-found' => 'Photo storage is unavailable. Ask your administrator to enable Firebase Storage.',
        'unauthorized' => 'Photo upload was denied. Check your account and Storage permissions.',
        _ => 'Could not update profile. Please try again.',
      };
      _message(messenger, message);
    } catch (_) {
      _message(messenger, 'Could not update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(BuildContext context) async {
    if (isPickingImage.value || isLoading.value) return;
    final messenger = ScaffoldMessenger.of(context);
    isPickingImage.value = true;
    try {
      final selected = await picker.pickImage(source: ImageSource.gallery);
      if (isClosed || selected == null) return;
      image = selected;
      update();
    } on PlatformException catch (error) {
      _message(
        messenger,
        error.code == 'already_active'
            ? 'Finish selecting the current photo first.'
            : 'Could not open photos. Check photo access in Android settings.',
      );
    } catch (_) {
      _message(messenger, 'Could not select a photo. Please try again.');
    } finally {
      isPickingImage.value = false;
    }
  }

  void _message(ScaffoldMessengerState messenger, String message) {
    if (!messenger.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void deleteProfile() async {
    String uid = auth.currentUser!.uid;
    try {
      await firestore.collection("employee").doc(uid).update({
        "avatar": FieldValue.delete(),
      });
      Get.back();

      Get.snackbar("Berhasil", "Berhasil delete avatar profile");
    } catch (e) {
      Get.snackbar(
        "Terjadi Kesalahan",
        "Tidak dapat delete avatar profile. Karena ${e.toString()}",
      );
    } finally {
      update();
    }
  }
}
