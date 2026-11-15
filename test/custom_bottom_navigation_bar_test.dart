import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:presence/app/controllers/page_index_controller.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:presence/app/widgets/custom_bottom_navigation_bar.dart';

void main() {
  tearDown(() => Get.reset());

  testWidgets('History opens without an attendance controller', (tester) async {
    Get.put(PageIndexController());
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.HOME,
        getPages: [
          GetPage(
            name: Routes.HOME,
            page: () =>
                Scaffold(bottomNavigationBar: CustomBottomNavigationBar()),
          ),
          GetPage(
            name: Routes.ALL_PRESENCE,
            page: () => const Scaffold(
              body: Text('Attendance history'),
              bottomNavigationBar: CustomBottomNavigationBar(selectedIndex: 1),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.ALL_PRESENCE);
    expect(find.text('Attendance history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final bottomInset in [0.0, 48.0]) {
    testWidgets('navigation fits with bottom inset $bottomInset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.put(PageIndexController());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              padding: EdgeInsets.only(bottom: bottomInset),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(bottomNavigationBar: CustomBottomNavigationBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(bar.bottom, 640);
      final destination = tester.getRect(find.byIcon(Icons.history_outlined));
      expect(destination.bottom, lessThanOrEqualTo(640 - bottomInset));
    });
  }
}
