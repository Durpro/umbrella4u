import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/core/app_controller.dart';
import 'package:umbrella4u/core/app_models.dart';
import 'package:umbrella4u/core/app_theme.dart';
import 'package:umbrella4u/data/umbrella_repository.dart';
import 'package:umbrella4u/features/settings/settings_screens.dart';

/// Reports itself as signed in so Settings renders the danger zone, and records
/// whether the delete actually reached the repository.
class _FakeRepository extends UmbrellaRepository {
  bool deleteCalled = false;

  @override
  bool get isLive => true;

  @override
  Future<void> deleteAccount() async => deleteCalled = true;
}

class _SignedInController extends AppController {
  _SignedInController(this.fake) : super(fake);

  final _FakeRepository fake;

  @override
  bool get isLoggedIn => true;

  @override
  UserProfile? get profile => UserProfile.fromMap(const {
    'id': 'member-1',
    'username': 'quiet_fern',
    'display_name': 'Quiet Fern',
    'onboarded': true,
  });
}

Future<void> _openSettings(
  WidgetTester tester,
  _SignedInController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(appThemeChoices.first),
      home: AppScope(controller: controller, child: const SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  final danger = find.text('Delete my account');
  await tester.scrollUntilVisible(
    danger,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(danger);
  await tester.pumpAndSettle();
}

void main() {
  late _FakeRepository repository;
  late _SignedInController controller;

  setUp(() {
    repository = _FakeRepository();
    controller = _SignedInController(repository);
    addTearDown(controller.dispose);
  });

  testWidgets('deleting stays blocked until the username is typed', (
    WidgetTester tester,
  ) async {
    await _openSettings(tester, controller);

    expect(find.text('Delete your account?'), findsOneWidget);

    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete forever'),
    );
    expect(deleteButton.onPressed, isNull);

    // A near miss must not unlock it either.
    await tester.enterText(find.byType(TextField).last, 'quiet_fer');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Delete forever'),
          )
          .onPressed,
      isNull,
    );
    expect(repository.deleteCalled, isFalse);
  });

  testWidgets('typing the username deletes the account', (
    WidgetTester tester,
  ) async {
    await _openSettings(tester, controller);

    await tester.enterText(find.byType(TextField).last, 'quiet_fern');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));

    // Not pumpAndSettle: the progress spinner runs until the screen is popped,
    // and here Settings is the root route so nothing pops it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.deleteCalled, isTrue);
  });

  testWidgets('backing out keeps the account', (WidgetTester tester) async {
    await _openSettings(tester, controller);

    await tester.tap(find.text('Keep my account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsNothing);
    expect(repository.deleteCalled, isFalse);
  });
}
