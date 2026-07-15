import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for leakless.
///
/// The design calls for **Outfit** on big numbers and headers (loaded at
/// runtime via `google_fonts`, no bundled binaries) with a clean, legible body.
/// Centralizing styles here keeps text consistent (quality rule #13/#14).
abstract final class AppTypography {
  AppTypography._();

  static const String _displayFamily = 'Outfit';

  /// Outfit text style with the requested [weight]/[size]/[height].
  static TextStyle _display(double size, FontWeight weight, {double? height}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: -0.5,
      );

  // Hero numbers (balance, amounts).
  static TextStyle get displayLarge =>
      _display(48, FontWeight.w700, height: 1.0);
  static TextStyle get displayMedium =>
      _display(34, FontWeight.w700, height: 1.05);
  static TextStyle get displaySmall =>
      _display(28, FontWeight.w600, height: 1.1);

  // Headings.
  static TextStyle get headlineMedium =>
      _display(22, FontWeight.w600, height: 1.2);
  static TextStyle get titleLarge => _display(18, FontWeight.w600, height: 1.2);
  static TextStyle get titleMedium =>
      _display(16, FontWeight.w600, height: 1.3);

  // Body & labels.
  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
  );

  /// The Material [TextTheme] consumed by [ThemeData].
  static TextTheme textTheme(Color onSurface) {
    final base = TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelSmall: labelSmall,
    );
    return base.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
      fontFamily: _displayFamily,
    );
  }
}
