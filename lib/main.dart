import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:presence/app/controllers/attendance_background_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:presence/app/controllers/page_index_controller.dart';
import 'package:presence/app/controllers/presence_controller.dart';

import 'firebase_options.dart';
import 'company_data.dart';

import 'package:get/get.dart';
import 'package:presence/app/controllers/notification_controller.dart';

import 'app/routes/app_pages.dart';
import 'app/style/app_theme.dart';
import 'app/controllers/theme_controller.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CompanyData.config;
  final appearance = Get.put(
    ThemeController(await SharedPreferences.getInstance()),
    permanent: true,
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationController().initNotification();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AttendanceBackgroundService.configure();
  }
  Get.put(PresenceController(), permanent: true);
  Get.put(PageIndexController(), permanent: true);
  runApp(
    StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Obx(
            () => MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: appearance.mode.value,
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }
        return Obx(
          () => GetMaterialApp(
            title: CompanyData.config.name,
            debugShowCheckedModeBanner: false,
            initialRoute: snapshot.data != null ? Routes.HOME : Routes.LOGIN,
            getPages: AppPages.routes,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appearance.mode.value,
          ),
        );
      },
    ),
  );
}
