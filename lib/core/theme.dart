import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Палитра «Сафо» — совпадает с сайтом (изумруд + янтарь), но с глубиной и мягкими градиентами.
@immutable
class SafoColors extends ThemeExtension<SafoColors> {
  const SafoColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.border,
    required this.danger,
  });

  final Color bg, surface, surface2, text, muted, primary, onPrimary, accent, border, danger;

  static const dark = SafoColors(
    bg: Color(0xFF0B130E),
    surface: Color(0xFF142019),
    surface2: Color(0xFF1B2B22),
    text: Color(0xFFE8F1EA),
    muted: Color(0xFF9FB2A5),
    primary: Color(0xFF4ADE80),
    onPrimary: Color(0xFF04200E),
    accent: Color(0xFFFBBF24),
    border: Color(0xFF2A3D30),
    danger: Color(0xFFF87171),
  );

  static const light = SafoColors(
    bg: Color(0xFFF4F9F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEAF3EC),
    text: Color(0xFF12221A),
    muted: Color(0xFF5A6B60),
    primary: Color(0xFF15803D),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFB45309),
    border: Color(0xFFD5E2D8),
    danger: Color(0xFFB91C1C),
  );

  LinearGradient get brand => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, Color.lerp(primary, const Color(0xFF059669), .6)!],
      );

  @override
  SafoColors copyWith() => this;

  @override
  SafoColors lerp(ThemeExtension<SafoColors>? other, double t) {
    if (other is! SafoColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SafoColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent),
      border: l(border, other.border),
      danger: l(danger, other.danger),
    );
  }
}

extension SafoThemeX on BuildContext {
  SafoColors get c => Theme.of(this).extension<SafoColors>()!;
  TextTheme get tt => Theme.of(this).textTheme;
}

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.dark ? SafoColors.dark : SafoColors.light;
  final base = ThemeData(brightness: b, useMaterial3: true);
  final text = base.textTheme.apply(bodyColor: c.text, displayColor: c.text).copyWith(
        displaySmall: TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.text),
        headlineMedium: TextStyle(fontSize: 26, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -.6, color: c.text),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.3, color: c.text),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text),
        bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: c.text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: c.text),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .1, color: c.text),
      );
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: c.primary, brightness: b).copyWith(
      primary: c.primary,
      onPrimary: c.onPrimary,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
    ),
    textTheme: text,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, foregroundColor: c.text),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.primary, width: 1.6)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surface2,
      contentTextStyle: TextStyle(color: c.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
