import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_models.dart';

class AppTheme {
  static const background = Color(0xFFE9DDF0);
  static const surface = Color(0xFFFCF8FD);
  static const softSurface = Color(0xFFF3EAF6);
  static const ink = Color(0xFF281B2E);
  static const secondaryInk = Color(0xFF66556D);
  static const mutedInk = Color(0xFF88768E);
  static const border = Color(0xFFD9CBE0);
  static const navigationPlum = Color(0xFF2E1836);
  static const navigationPlumDeep = Color(0xFF211027);
  static const navigationOn = Color(0xFFFFF7FC);
  static const navigationMuted = Color(0xFFC8B4CD);

  static ThemeData build(AppThemeChoice choice) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: choice.accent,
          brightness: Brightness.light,
          surface: surface,
        ).copyWith(
          primary: choice.accent,
          onPrimary: Colors.white,
          secondary: choice.deep,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: ink,
          outline: border,
          outlineVariant: border,
          surfaceTint: choice.accent,
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: choice.accent.withValues(alpha: 0.05),
      focusColor: choice.accent.withValues(alpha: 0.08),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: ink,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
          height: 1.08,
        ),
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.12,
        ),
        headlineSmall: TextStyle(
          color: ink,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: secondaryInk, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: secondaryInk, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: mutedInk, fontSize: 12, height: 1.35),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softSurface,
        hintStyle: const TextStyle(color: mutedInk),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: choice.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD75068)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD75068), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: choice.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: choice.accent,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: choice.accent.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: softSurface,
        selectedColor: choice.accent.withValues(alpha: 0.14),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        labelStyle: const TextStyle(
          color: secondaryInk,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: choice.accent,
        linearTrackColor: border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navigationPlum,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }
}

class CozyScrollBehavior extends MaterialScrollBehavior {
  const CozyScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
