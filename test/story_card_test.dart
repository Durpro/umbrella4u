import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/core/app_controller.dart';
import 'package:umbrella4u/core/app_models.dart';
import 'package:umbrella4u/core/app_theme.dart';
import 'package:umbrella4u/data/umbrella_repository.dart';
import 'package:umbrella4u/features/feed/story_card.dart';

Widget _host(StoryItem story, AppController controller) {
  return MaterialApp(
    theme: AppTheme.build(appThemeChoices.first),
    home: AppScope(
      controller: controller,
      child: Scaffold(
        body: SingleChildScrollView(child: StoryCard(story: story)),
      ),
    ),
  );
}

void main() {
  late AppController controller;

  setUp(() {
    controller = AppController(UmbrellaRepository());
    addTearDown(controller.dispose);
  });

  testWidgets('a sensitive story stays covered until the reader reveals it', (
    WidgetTester tester,
  ) async {
    final story = StoryItem.fromMap(const {
      'id': 'story-covered',
      'text': 'A story that is covered.',
      'content_warning': true,
    });

    await tester.pumpWidget(_host(story, controller));
    await tester.pumpAndSettle();

    expect(find.text('A story that is covered.'), findsNothing);
    expect(find.text('Sensitive content'), findsOneWidget);

    await tester.tap(find.text('Reveal story'));
    await tester.pumpAndSettle();

    expect(find.text('A story that is covered.'), findsOneWidget);
    expect(find.text('Reveal story'), findsNothing);
  });

  testWidgets('a story without a warning is readable straight away', (
    WidgetTester tester,
  ) async {
    final story = StoryItem.fromMap(const {
      'id': 'story-plain',
      'text': 'An ordinary story.',
    });

    await tester.pumpWidget(_host(story, controller));
    await tester.pumpAndSettle();

    expect(find.text('An ordinary story.'), findsOneWidget);
    expect(find.text('Reveal story'), findsNothing);
  });
}
