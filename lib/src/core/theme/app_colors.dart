import 'package:flutter/material.dart';

/// Semantic color palette for the **leakless** "Liquid Glass" design system.
///
/// Exposed as a [ThemeExtension] so widgets read colors through
/// `context.colors` instead of hardcoding hex values (quality rule #13/#14).
///
/// The look is a fresh, light, translucent iOS-style theme — **not** dark mode:
/// a cool ice-blue background, frosted white glass cards, and four accent
/// colors mapped to financial meaning (income, expense, alert, goal).
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.income,
    required this.expense,
    required this.alert,
    required this.goal,
    required this.incomeSoft,
    required this.expenseSoft,
    required this.alertSoft,
    required this.goalSoft,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.shadow,
    required this.scrim,
    required this.surface,
    required this.divider,
    required this.disabled,
  });

  /// Base scaffold background.
  final Color background;

  /// Organic background gradient stops (top → bottom).
  final Color backgroundTop;
  final Color backgroundBottom;

  /// Deep slate, used for headings and primary numbers.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Mint green — income, savings and "future" money.
  final Color income;

  /// Coral — meaningful expenses.
  final Color expense;

  /// Amber — budget warnings and limit alerts.
  final Color alert;

  /// Electric sky blue — savings goals (also the brand primary).
  final Color goal;

  /// Soft tinted backgrounds for the four accents (pills, chips, fills).
  final Color incomeSoft;
  final Color expenseSoft;
  final Color alertSoft;
  final Color goalSoft;

  /// Frosted glass fill (semi-transparent white over the blurred background).
  final Color glassFill;
  final Color glassFillStrong;

  /// Refraction border drawn around glass surfaces.
  final Color glassBorder;

  /// Top-edge light highlight that sells the "liquid glass" refraction.
  final Color glassHighlight;

  /// Diffuse drop shadow under glass cards.
  final Color shadow;

  /// Modal scrim behind bottom sheets / dialogs.
  final Color scrim;

  /// Opaque surface (used when blur is undesirable, e.g. nav bar fallback).
  final Color surface;

  final Color divider;
  final Color disabled;

  /// The brand primary. Mapped to [goal] (the liquid blue).
  Color get primary => goal;

  /// The default leakless palette.
  static const AppColors light = AppColors(
    background: Color(0xFFF0F4FA),
    backgroundTop: Color(0xFFF4F8FF),
    backgroundBottom: Color(0xFFE6EEFB),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    income: Color(0xFF00D09C),
    expense: Color(0xFFFF5A79),
    alert: Color(0xFFFFB03A),
    goal: Color(0xFF3082FF),
    incomeSoft: Color(0x1A00D09C),
    expenseSoft: Color(0x1AFF5A79),
    alertSoft: Color(0x1AFFB03A),
    goalSoft: Color(0x1A3082FF),
    glassFill: Color(0x8CFFFFFF), // white @ 55%
    glassFillStrong: Color(0xCCFFFFFF), // white @ 80%
    glassBorder: Color(0x99FFFFFF), // white @ 60%
    glassHighlight: Color(0xB3FFFFFF),
    shadow: Color(0x1A1E293B),
    scrim: Color(0x401E293B),
    surface: Color(0xFFFFFFFF),
    divider: Color(0x141E293B),
    disabled: Color(0xFFCBD5E1),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundTop,
    Color? backgroundBottom,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? income,
    Color? expense,
    Color? alert,
    Color? goal,
    Color? incomeSoft,
    Color? expenseSoft,
    Color? alertSoft,
    Color? goalSoft,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassHighlight,
    Color? shadow,
    Color? scrim,
    Color? surface,
    Color? divider,
    Color? disabled,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundTop: backgroundTop ?? this.backgroundTop,
      backgroundBottom: backgroundBottom ?? this.backgroundBottom,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      alert: alert ?? this.alert,
      goal: goal ?? this.goal,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      alertSoft: alertSoft ?? this.alertSoft,
      goalSoft: goalSoft ?? this.goalSoft,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      surface: surface ?? this.surface,
      divider: divider ?? this.divider,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      backgroundBottom: Color.lerp(
        backgroundBottom,
        other.backgroundBottom,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      goal: Color.lerp(goal, other.goal, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      alertSoft: Color.lerp(alertSoft, other.alertSoft, t)!,
      goalSoft: Color.lerp(goalSoft, other.goalSoft, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}

/// Read [AppColors] from the active theme: `context.colors.income`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
