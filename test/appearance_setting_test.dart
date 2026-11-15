import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presence/app/controllers/theme_controller.dart';
import 'package:presence/app/style/app_theme.dart';
import 'package:presence/app/widgets/appearance_setting.dart';
import 'package:presence/app/widgets/dashboard_panel.dart';

void main() {
  testWidgets('appearance persists and Automatic responds to system changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences);
    expect(controller.mode.value, ThemeMode.system);
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(
      Obx(
        () => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.mode.value,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SingleChildScrollView(
                child: DashboardPanel(
                  child: AppearanceSetting(controller: controller),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(AppearanceSetting))).brightness;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    expect(ThemeController(preferences).mode.value, ThemeMode.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    expect(ThemeController(preferences).mode.value, ThemeMode.system);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing appearance keeps the current GetX route', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(() => Get.reset());
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      Obx(
        () => GetMaterialApp(
          initialRoute: '/home',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.mode.value,
          getPages: [
            GetPage(
              name: '/home',
              page: () => const Scaffold(body: Text('Home')),
            ),
            GetPage(
              name: '/profile',
              page: () =>
                  Scaffold(body: AppearanceSetting(controller: controller)),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    Get.toNamed('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/profile');
    expect(
      Theme.of(tester.element(find.byType(AppearanceSetting))).brightness,
      Brightness.dark,
    );
    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  test('unknown saved appearance defaults to Automatic', () async {
    SharedPreferences.setMockInitialValues({'appearance': 'unknown'});
    expect(
      ThemeController(await SharedPreferences.getInstance()).mode.value,
      ThemeMode.system,
    );
  });
}
