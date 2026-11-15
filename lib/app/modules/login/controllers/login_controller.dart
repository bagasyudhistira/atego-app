import 'package:firebase_auth/firebase_auth.dart';
import 'package:presence/company_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presence/app/controllers/page_index_controller.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:presence/app/widgets/dialog/custom_alert_dialog.dart';
import 'package:presence/app/widgets/toast/custom_toast.dart';

class LoginController extends GetxController {
  final pageIndexController = Get.find<PageIndexController>();
  RxBool isLoading = false.obs;
  RxBool obsecureText = true.obs;
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  checkDefaultPassword() {
    if (passC.text == CompanyData.defaultPassword)
      Get.toNamed(Routes.NEW_PASSWORD);
    else {
      Get.offAllNamed(Routes.HOME);
      pageIndexController.changePage(0);
    }
  }

  @override
  void onClose() {
    emailC.dispose();
    passC.dispose();
    super.onClose();
  }

  Future<void> login() async {
    if (isLoading.value) return;
    if (emailC.text.trim().isNotEmpty && passC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: emailC.text.trim(),
          password: passC.text,
        );

        if (credential.user != null) {
          if (credential.user!.emailVerified) {
            isLoading.value = false;
            checkDefaultPassword();
          } else {
            CustomAlertDialog.showPresenceAlert(
              title: "Email not yet verified",
              message: "Are you want to send email verification?",
              onCancel: () => Get.back(),
              onConfirm: () async {
                try {
                  await credential.user!.sendEmailVerification();
                  Get.back();
                  CustomToast.successToast(
                    "Success",
                    "We've send email verification to your email",
                  );
                  isLoading.value = false;
                } catch (e) {
                  CustomToast.errorToast(
                    "Error",
                    "Cant send email verification. Error because : ${e.toString()}",
                  );
                }
              },
            );
          }
        }
        isLoading.value = false;
      } on FirebaseAuthException catch (e) {
        isLoading.value = false;
        if (e.code == 'user-not-found') {
          CustomToast.errorToast("Error", "Account not found");
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          CustomToast.errorToast(
            "Unable to log in",
            "Check your email and password.",
          );
        } else {
          CustomToast.errorToast("Unable to log in", "Please try again.");
        }
      } catch (_) {
        CustomToast.errorToast("Unable to log in", "Please try again.");
      } finally {
        if (!isClosed) isLoading.value = false;
      }
    } else {
      CustomToast.errorToast(
        "Error",
        "You need to fill email and password form",
      );
    }
  }
}
