import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color bg = Color(0xFFFAF9F6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF7A7A7A);
  static const Color border = Color(0xFFD8D4CC);
  static const Color mint = Color(0xFFB8E8D4);
  static const Color mintSoft = Color(0xFFDFF4EC);
  static const Color pink = Color(0xFFF9C8D4);
  static const Color pinkSoft = Color(0xFFFDE8ED);
  static const Color sky = Color(0xFFB8D8F0);
  static const Color skySoft = Color(0xFFDEEEF9);
  static const Color yellow = Color(0xFFF9E8A0);
  static const Color peach = Color(0xFFFDD5B0);
}

class AppBorderRadius {
  AppBorderRadius._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 100;
}

class AppTheme {
  AppTheme._();

  static const double borderWidth = 1.5;

  static TextTheme get _textTheme {
    final bodyFont = GoogleFonts.dmSansTextTheme();
    final displayFont = GoogleFonts.playfairDisplayTextTheme();

    return bodyFont.copyWith(
      displayLarge: displayFont.displayLarge?.copyWith(color: AppColors.ink),
      displayMedium: displayFont.displayMedium?.copyWith(color: AppColors.ink),
      displaySmall: displayFont.displaySmall?.copyWith(color: AppColors.ink),
      headlineLarge: displayFont.headlineLarge?.copyWith(color: AppColors.ink),
      headlineMedium: displayFont.headlineMedium?.copyWith(color: AppColors.ink),
      headlineSmall: displayFont.headlineSmall?.copyWith(color: AppColors.ink),
      titleLarge: displayFont.titleLarge?.copyWith(color: AppColors.ink),
      titleMedium: displayFont.titleMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: displayFont.titleSmall?.copyWith(color: AppColors.ink),
      bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.ink),
      bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.ink),
      bodySmall: bodyFont.bodySmall?.copyWith(color: AppColors.muted),
      labelLarge: bodyFont.labelLarge?.copyWith(color: AppColors.ink),
      labelMedium: bodyFont.labelMedium?.copyWith(color: AppColors.muted),
      labelSmall: bodyFont.labelSmall?.copyWith(color: AppColors.muted),
    );
  }

  static ThemeData get theme {
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.white,
        secondary: AppColors.mint,
        onSecondary: AppColors.ink,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        outline: AppColors.border,
        error: AppColors.pink,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        shape: const Border(
          bottom: BorderSide(
            color: AppColors.ink,
            width: borderWidth,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.ink,
            width: borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.pink,
            width: borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.pink,
            width: borderWidth,
          ),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.muted,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.muted,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
            side: const BorderSide(
              color: AppColors.ink,
              width: borderWidth,
            ),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          shadowColor: AppColors.mint,
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 0;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          ),
          side: const BorderSide(
            color: AppColors.ink,
            width: borderWidth,
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.mint,
        disabledColor: AppColors.bg,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          side: const BorderSide(
            color: AppColors.border,
            width: borderWidth,
          ),
        ),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          side: const BorderSide(
            color: AppColors.ink,
            width: borderWidth,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }

  /// Neo-brutalist card decoration with ink box shadow
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.ink,
          width: borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      );

  /// Focused input decoration with ink box shadow
  static BoxDecoration get focusedInputDecoration => BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(
          color: AppColors.ink,
          width: borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      );

  /// Pill button decoration with colored shadow
  static BoxDecoration pillButtonDecoration({
    Color backgroundColor = AppColors.ink,
    Color shadowColor = AppColors.mint,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      border: Border.all(
        color: AppColors.ink,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: const Offset(3, 3),
          blurRadius: 0,
        ),
      ],
    );
  }
}
