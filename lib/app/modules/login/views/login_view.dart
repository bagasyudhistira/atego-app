import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:presence/app/widgets/login_panel.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Obx(
      () => LoginPanel(
        emailController: controller.emailC,
        passwordController: controller.passC,
        busy: controller.isLoading.value,
        obscurePassword: controller.obsecureText.value,
        onTogglePassword: () =>
            controller.obsecureText.toggle(),
        onLogin: controller.login,
        onForgotPassword: () => Get.toNamed(Routes.FORGOT_PASSWORD),
      ),
    ),
  );
}
