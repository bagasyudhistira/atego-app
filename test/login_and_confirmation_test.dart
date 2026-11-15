import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presence/app/style/app_theme.dart';
import 'package:presence/app/modules/add_employee/views/add_employee_view.dart';
import 'package:presence/app/widgets/dialog/action_confirmation.dart';
import 'package:presence/app/widgets/login_panel.dart';

void main() {
  testWidgets('employee creation route exposes no provisioning controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: AddEmployeeView()),
    );
    expect(find.text('Employee creation unavailable'), findsOneWidget);
    expect(find.textContaining('provision accounts securely'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'login validates fields, submits with keyboard, and masks password',
    (tester) async {
      final email = TextEditingController();
      final password = TextEditingController();
      addTearDown(email.dispose);
      addTearDown(password.dispose);
      var logins = 0;
      var obscure = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => LoginPanel(
                emailController: email,
                passwordController: password,
                busy: false,
                obscurePassword: obscure,
                onTogglePassword: () => setState(() => obscure = !obscure),
                onLogin: () => logins++,
                onForgotPassword: () {},
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Log in'));
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(logins, 0);
      await tester.enterText(find.byType(TextFormField).first, 'invalid');
      await tester.enterText(find.byType(TextFormField).last, 'password');
      await tester.ensureVisible(find.text('Log in'));
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Enter a valid email.'), findsOneWidget);
      expect(logins, 0);
      await tester.enterText(
        find.byType(TextFormField).first,
        'user@company.com',
      );
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        false,
      );
      await tester.tap(find.byType(TextFormField).last);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(logins, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'login fits narrow screens, large text, keyboard, and dark mode',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final email = TextEditingController();
      final password = TextEditingController();
      addTearDown(email.dispose);
      addTearDown(password.dispose);
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 600),
                viewInsets: EdgeInsets.only(bottom: 240),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: LoginPanel(
                  emailController: email,
                  passwordController: password,
                  busy: true,
                  obscurePassword: true,
                  onTogglePassword: () {},
                  onLogin: () => fail('Busy form must not submit'),
                  onForgotPassword: () => fail('Busy form must not navigate'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Logging in…'));
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField).first).enabled,
          false,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final label in ['Log out', 'Check in', 'Check out']) {
    testWidgets('$label requires explicit confirmation', (tester) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  confirmed = await confirmAction(
                    context,
                    title: '$label?',
                    message: 'Confirm this action.',
                    confirmLabel: label,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
      }

      await open();
      expect(confirmed, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(confirmed, false);
      await open();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(confirmed, false);
      await open();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(confirmed, true);
    });
  }
}
