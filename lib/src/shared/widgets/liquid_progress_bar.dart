import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A horizontal progress bar whose fill behaves like a gently rippling liquid.
///
/// Used for goal progress and savings-rate visuals. [value] is clamped to
/// `0..1`; [color] defaults to the goal blue but goals/budgets pass their own.
class LiquidProgressBar extends StatefulWidget {
  const LiquidProgressBar({
    required this.value,
    this.color,
    this.height = 16,
    this.animateWave = true,
    super.key,
  });

  final double value;
  final Color? color;
  final double height;
  final bool animateWave;

  @override
  State<LiquidProgressBar> createState() => _LiquidProgressBarState();
}

class _LiquidProgressBarState extends State<LiquidProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.liquid,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animateWave) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = widget.color ?? colors.goal;
    return ClipRRect(
      borderRadius: AppRadii.pillRadius,
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _LiquidBarPainter(
                value: widget.value.clamp(0, 1).toDouble(),
                phase: _controller.value * 2 * math.pi,
                fill: fill,
                track: colors.glassFill,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _LiquidBarPainter extends CustomPainter {
  _LiquidBarPainter({
    required this.value,
    required this.phase,
    required this.fill,
    required this.track,
  });

  final double value;
  final double phase;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = track;
    canvas.drawRect(Offset.zero & size, trackPaint);

    if (value <= 0) return;

    final fillWidth = size.width * value;
    final amplitude = math.min(2.5, size.height * 0.18);
    final path = Path()..moveTo(0, size.height);

    const segments = 24;
    for (var i = 0; i <= segments; i++) {
      final x = fillWidth * (i / segments);
      final y = amplitude * math.sin((i / segments * 2 * math.pi) + phase);
      path.lineTo(x, size.height * 0.5 + y - size.height * 0.5 + amplitude);
    }
    path
      ..lineTo(fillWidth, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [fill, Color.lerp(fill, Colors.white, 0.25)!],
      ).createShader(Rect.fromLTWH(0, 0, fillWidth, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidBarPainter old) =>
      old.value != value || old.phase != phase || old.fill != fill;
}
