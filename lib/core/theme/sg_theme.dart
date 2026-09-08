import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sg_colors.dart';
import 'sg_radius.dart';

abstract final class SgTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: SgColors.orange,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: SgColors.orange,
      onPrimary: SgColors.jet,
      secondary: SgColors.moonstone,
      onSecondary: SgColors.jet,
      surface: isDark ? SgColors.darkSurface : SgColors.lightSurface,
      onSurface: isDark ? SgColors.darkText : SgColors.lightText,
    );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? SgColors.darkBackground : SgColors.lightBackground,
      useMaterial3: true,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: isDark ? SgColors.darkText : SgColors.lightText,
      displayColor: isDark ? SgColors.darkText : SgColors.lightText,
    );

    return base.copyWith(
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SgColors.orange,
          foregroundColor: SgColors.jet,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SgRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? SgColors.darkSurface : SgColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SgRadius.lg),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? SgColors.darkSurface : SgColors.lightSurface,
        indicatorColor: SgColors.orange.withValues(alpha: 0.14),
        height: 72,
      ),
    );
  }
}
