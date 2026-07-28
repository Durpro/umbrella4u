import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/core/app_controller.dart';
import 'package:umbrella4u/core/app_models.dart';
import 'package:umbrella4u/core/app_theme.dart';
import 'package:umbrella4u/data/umbrella_repository.dart';
import 'package:umbrella4u/features/profile/profile_screens.dart';

final _profile = UserProfile.fromMap(const {
  'id': 'member-1',
  'username': 'quiet_fern',
  'display_name': 'Quiet Fern',
  'pronouns': 'they/them',
  'about_me': 'Rainy-day sketches.',
  'avatar_url': 'emoji:🌿',
  'tags': ['music', 'art'],
  'onboarded': true,
});

/// Pushes the editor so the route can pop, which is what the guard reacts to.
Future<void> _openEditor(WidgetTester tester, AppController controller) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(appThemeChoices.first),
      home: AppScope(
        controller: controller,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => EditProfileScreen(profile: _profile),
                  ),
                ),
                child: const Text('open editor'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open editor'));
  await tester.pumpAndSettle();
}

void main() {
  late AppController controller;

  setUp(() {
    controller = AppController(UmbrellaRepository());
    addTearDown(controller.dispose);
  });

  testWidgets('leaving an edited profile asks before discarding', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester, controller);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name'),
      'Quieter Fern',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Leave without saving?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    // Still in the editor, with the edit intact.
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Quieter Fern'), findsOneWidget);
  });

  testWidgets('discarding the changes leaves the editor', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester, controller);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name'),
      'Quieter Fern',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('open editor'), findsOneWidget);
  });

  testWidgets('an untouched profile leaves without a prompt', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester, controller);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Leave without saving?'), findsNothing);
    expect(find.text('open editor'), findsOneWidget);
  });

  testWidgets('changing only the avatar still counts as an edit', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester, controller);

    final butterfly = find.text('🦋');
    await tester.ensureVisible(butterfly);
    await tester.pumpAndSettle();
    await tester.tap(butterfly);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Leave without saving?'), findsOneWidget);
  });
}
