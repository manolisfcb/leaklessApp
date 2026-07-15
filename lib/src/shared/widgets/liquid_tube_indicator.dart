import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A vertical glass "tube" that fills from the bottom with rippling liquid.
///
/// This is the budget visual from the design: as a category's spend grows the
/// tube fills, and the caller swaps [color] to amber (≥75%) or coral (≥100%).
class LiquidTubeIndicator extends StatefulWidget {
  const LiquidTubeIndicator({
    required this.value,
    required this.color,
    this.width = 56,
    this.height = 160,
    super.key,
  });

  /// Fill ratio, clamped to `0..1` for the visual (values >1 still read full).
  final double value;
  final Color color;
  final double width;
  final double height;

  @override
  State<LiquidTubeIndicator> createState() => _LiquidTubeIndicatorState();
}

class _LiquidTubeIndicatorState extends State<LiquidTubeIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.liquid,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(widget.width / 2);
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: colors.glassFill,
        border: Border.all(color: colors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _TubePainter(
              value: widget.value.clamp(0, 1).toDouble(),
              phase: _controller.value * 2 * math.pi,
              color: widget.color,
            ),
            size: Size(widget.width, widget.height),
          ),
        ),
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  _TubePainter({required this.value, required this.phase, required this.color});

  final double value;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;

    final fillTop = size.height * (1 - value);
    final amplitude = math.min(4.0, size.width * 0.12);
    final path = Path()..moveTo(0, size.height);

    const segments = 24;
    for (var i = 0; i <= segments; i++) {
      final x = size.width * (i / segments);
      final y =
          fillTop + amplitude * math.sin((i / segments * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(color, Colors.white, 0.25)!, color],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TubePainter old) =>
      old.value != value || old.phase != phase || old.color != color;
}
