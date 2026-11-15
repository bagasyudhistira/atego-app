import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:presence/app/controllers/page_index_controller.dart';
import 'package:presence/app/controllers/presence_controller.dart';
import 'package:presence/app/widgets/custom_bottom_navigation_bar.dart';

class _IdlePresenceController extends GetxController
    implements PresenceController {
  @override
  final isLoading = false.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());

  for (final bottomInset in [0.0, 48.0]) {
    testWidgets('navigation fits with bottom inset $bottomInset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.put<PresenceController>(_IdlePresenceController());
      Get.put(PageIndexController());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              padding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: Scaffold(bottomNavigationBar: CustomBottomNavigationBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      final button = tester.getRect(find.byType(FloatingActionButton));
      expect(button.bottom, lessThanOrEqualTo(640 - bottomInset));
      final bar = tester.getRect(find.byType(BottomAppBar));
      expect(bar.bottom, 640 - bottomInset);
    });
  }
}
