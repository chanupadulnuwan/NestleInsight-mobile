import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBrown = Color(0xFF8A6B53);
  static const Color primaryBrownDark = Color(0xFF5F4837);
  static const Color headerGradientStart = Color(0xFF6E5A4E);
  static const Color headerGradientEnd = Color(0xFF8C7566);
  static const Color promotionMutedRed = Color(0xFFC85C53);
  static const Color addToCartClay = Color(0xFFB78363);
  static const Color proceedOrderOlive = Color(0xFF6F7F58);
  static const Color rejectOrderRed = Color(0xFF9B4B46);
  static const Color securitySlate = Color(0xFF61758A);
  static const Color surfaceTint = Color(0xFFF6EBDD);
  static const Color surfaceWarm = Color(0xFFFFFBF7);
  static const Color background = Colors.white;
  static const Color outlineWarm = Color(0xFFD5C1AF);
  static const Color textDark = Color(0xFF4F3D31);
  static const Color textSoft = Color(0xFF8C7663);

  // Added aliases for strict prompt adherence
  static const Color kBrown = primaryBrown;
  static const Color kCream = surfaceTint;
  static const Color kOrange = Color(0xFFD97753); // Suitable orange for the palette
  static const Color kTextDark = textDark;

  static ThemeData get light {
    final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryBrown,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryBrown,
          secondary: const Color(0xFFD9BE9D),
          surface: Colors.white,
          onSurface: textDark,
          outline: outlineWarm,
          outlineVariant: const Color(0xFFE7D9CD),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textDark,
          height: 1.4,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textDark,
          height: 1.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfaceWarm,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: outlineWarm.withAlpha(120)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: textSoft,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: textSoft),
        helperStyle: const TextStyle(color: textSoft),
        errorMaxLines: 2,
        prefixIconColor: primaryBrownDark,
        suffixIconColor: textSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outlineWarm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outlineWarm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryBrown, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBrownDark,
          side: const BorderSide(color: outlineWarm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBrownDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryBrownDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
