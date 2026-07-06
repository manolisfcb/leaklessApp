import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A compact bar chart for short trend series (e.g. the last few months of
/// spend). Bars scale against the largest value in [values]; the last bar
/// (the current period) is drawn in [highlightColor] so it stands out from
/// the rest.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    required this.values,
    required this.labels,
    this.height = 96,
    this.color,
    this.highlightColor,
    super.key,
  }) : assert(values.length == labels.length, 'values and labels must match');

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color? color;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = color ?? colors.goal;
    final highlight = highlightColor ?? colors.expense;
    final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m);
    final lastIndex = values.length - 1;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, v) in values.indexed) ...[
            if (i > 0) AppSpacing.gapSm,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxValue > 0
                            ? (v / maxValue).clamp(0.04, 1.0)
                            : 0.04,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i == lastIndex
                                ? highlight
                                : fill.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    labels[i],
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
