import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/core/app_theme.dart';
import 'package:umbrella4u/main.dart';

void main() {
  testWidgets('the five-tab mobile shell opens each real app area', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const UmbrellaApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-inbox')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-post')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-profile')), findsOneWidget);
    expect(find.text('Haven'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-inbox')));
    await tester.pumpAndSettle();
    expect(find.text('Umbrellas, kind words, and thank-yous.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-post')));
    await tester.pumpAndSettle();
    expect(find.text('Share your weather'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpAndSettle();
    expect(find.text('Search Haven'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);

    final context = tester.element(find.byKey(const ValueKey('nav-profile')));
    expect(Theme.of(context).scaffoldBackgroundColor, AppTheme.background);
  });

  testWidgets('search discovery exposes the website categories', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const UmbrellaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpAndSettle();

    expect(find.text('Identity'), findsOneWidget);
    expect(find.text('School life'), findsOneWidget);
    expect(find.text('Mental health'), findsOneWidget);
    expect(find.text('Small wins'), findsOneWidget);
  });

  testWidgets('a horizontal swipe changes tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const UmbrellaApp());
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(195, 420), const Offset(-130, 0));
    await tester.pumpAndSettle();

    expect(find.text('Umbrellas, kind words, and thank-yous.'), findsOneWidget);
  });

  testWidgets('the Home bell opens a dismissible notification preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const UmbrellaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('View all inbox'), findsOneWidget);

    await tester.tap(find.text('View all inbox'));
    await tester.pumpAndSettle();

    expect(find.text('Umbrellas, kind words, and thank-yous.'), findsOneWidget);
  });
}
