import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/main.dart';

void main() {
  testWidgets('bottom navigation opens every placeholder page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UmbrellaApp());

    expect(find.text('Umbrella4U'), findsOneWidget);
    expect(find.byIcon(Icons.umbrella_rounded), findsWidgets);

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Three new moments are waiting.'), findsOneWidget);

    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Share something worth remembering.'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Find people, circles, and moments.'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your corner of Umbrella4U.'), findsOneWidget);
  });
}
