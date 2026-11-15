import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presence/app/style/app_theme.dart';
import 'package:presence/app/widgets/location_status_panel.dart';
import 'package:presence/app/widgets/presence_card.dart';
import 'package:presence/app/widgets/presence_tile.dart';

void main() {
  Future<void> render(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('attendance states and weekend schedule fit large text', (
    tester,
  ) async {
    for (final entry in [
      (null, 'Not checked in'),
      (
        {
          'masuk': {'date': '2026-11-15T08:00:00'},
        },
        'Checked in',
      ),
      (
        {
          'masuk': {'date': '2026-11-15T08:00:00'},
          'keluar': {'date': '2026-11-15T16:00:00'},
        },
        'Checked out',
      ),
    ]) {
      await render(
        tester,
        PresenceCard(
          userData: const {},
          todayPresenceData: entry.$1,
          date: DateTime(2026, 11, 15),
        ),
      );
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('No scheduled shift today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'cached attendance and malformed time do not imply fresh confirmation',
    (tester) async {
      await render(
        tester,
        PresenceCard(
          userData: const {},
          todayPresenceData: const {
            'masuk': {'date': 'invalid'},
          },
          date: DateTime(2026, 11, 16),
          fromCache: true,
        ),
      );
      expect(find.text('Shift 08:00 – 16:00'), findsOneWidget);
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unavailable location differs from outside office and refresh remains usable',
    (tester) async {
      var refreshed = false;
      Widget panel(bool? inOffice) => LocationStatusPanel(
        gps: 'Enabled',
        permission: 'Granted',
        distance: '350 m',
        inOffice: inOffice,
        lastUpdate: null,
        checking: false,
        onRefresh: () => refreshed = true,
      );
      await render(tester, panel(null));
      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.textContaining('Outside office'), findsNothing);
      await tester.ensureVisible(find.text('Refresh location'));
      await tester.tap(find.text('Refresh location'));
      expect(refreshed, isTrue);
      await render(tester, panel(false));
      expect(find.text('Away from the office'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual action follows attendance state and prevents repeated taps',
    (tester) async {
      var checkIns = 0;
      var checkOuts = 0;
      Widget card(Map<String, dynamic>? data, {bool busy = false}) =>
          PresenceCard(
            userData: const {},
            todayPresenceData: data,
            onCheckIn: () => checkIns++,
            onCheckOut: () => checkOuts++,
            busy: busy,
          );
      await render(tester, card(null));
      await tester.ensureVisible(find.text('Check in'));
      await tester.tap(find.text('Check in'));
      expect(checkIns, 1);
      await render(
        tester,
        card({
          'masuk': {'date': '2026-11-16T08:00:00'},
        }),
      );
      await tester.ensureVisible(find.text('Check out'));
      await tester.tap(find.text('Check out'));
      expect(checkOuts, 1);
      await render(tester, card(null, busy: true));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await render(tester, card({'masuk': {}, 'keluar': {}}));
      expect(find.text('Attendance complete'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending location refresh keeps the known office status', (
    tester,
  ) async {
    await render(
      tester,
      LocationStatusPanel(
        gps: 'Enabled',
        permission: 'Granted',
        distance: '50 m',
        inOffice: true,
        lastUpdate: DateTime(2026, 11, 16, 8),
        checking: true,
        onRefresh: () {},
      ),
    );
    expect(find.text('Location unavailable'), findsNothing);
    expect(find.textContaining('50 m'), findsOneWidget);
    expect(find.text('Refreshing…'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent attendance wraps and tolerates missing dates', (
    tester,
  ) async {
    await render(
      tester,
      const PresenceTile(
        presenceData: {
          'date': 'invalid',
          'masuk': {'date': '2026-11-16T08:30:00', 'on_time': false},
        },
      ),
    );
    expect(find.text('Date unavailable'), findsOneWidget);
    expect(find.text('Late check-in'), findsOneWidget);
    expect(find.text('Check-out  —'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
