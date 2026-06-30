import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../domain/models/money.dart';

/// Renders a [Money] value with the brand number typography.
///
/// Pass [color] to tint it (e.g. income green / expense coral) or [signDisplay]
/// to prefix an explicit `+`/`-`. Keeping money rendering in one widget avoids
/// inconsistent formatting across screens (quality rule #1).
class AmountText extends StatelessWidget {
  const AmountText({
    required this.money,
    this.style,
    this.color,
    this.signDisplay = SignDisplay.none,
    this.compact = false,
    super.key,
  });

  final Money money;
  final TextStyle? style;
  final Color? color;
  final SignDisplay signDisplay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveStyle =
        (style ?? AppTypography.displaySmall).copyWith(color: color ?? colors.textPrimary);

    final body = compact
        ? money.absolute.formatCompact()
        : money.absolute.format();

    final text = switch (signDisplay) {
      SignDisplay.none => money.format(),
      SignDisplay.always => '${money.isNegative ? '−' : '+'}$body',
      SignDisplay.negativeOnly => money.isNegative ? '−$body' : body,
    };

    return Text(text, style: effectiveStyle);
  }
}

/// How an [AmountText] renders the +/- sign.
enum SignDisplay { none, always, negativeOnly }
