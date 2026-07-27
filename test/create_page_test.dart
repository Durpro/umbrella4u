import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/main.dart';

const _crisisSheetTitle = 'You deserve live support right now';

Future<void> _openComposer(WidgetTester tester, String story) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const UmbrellaApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-post')));
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextField, 'Your story'), story);
  await tester.pumpAndSettle();

  final shareButton = find.widgetWithText(FilledButton, 'Share story');
  await tester.ensureVisible(shareButton);
  await tester.pumpAndSettle();
  await tester.tap(shareButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first-person crisis language is held back for live support', (
    WidgetTester tester,
  ) async {
    await _openComposer(tester, 'I keep thinking about killing myself.');

    expect(find.text(_crisisSheetTitle), findsOneWidget);
  });

  testWidgets('ordinary venting is not mistaken for a crisis', (
    WidgetTester tester,
  ) async {
    await _openComposer(
      tester,
      'Exams feel hopeless and I can’t go on like this forever.',
    );

    // It should reach the kindness-agreement check instead, which only happens
    // once the crisis filter has let the story through.
    expect(find.text(_crisisSheetTitle), findsNothing);
    expect(
      find.text('Please confirm the kindness agreement before sharing.'),
      findsOneWidget,
    );
  });

  testWidgets('asking how to support a friend is not blocked', (
    WidgetTester tester,
  ) async {
    await _openComposer(
      tester,
      'My friend told me she is suicidal. How do I actually help her?',
    );

    expect(find.text(_crisisSheetTitle), findsNothing);
    expect(
      find.text('Please confirm the kindness agreement before sharing.'),
      findsOneWidget,
    );
  });
}
