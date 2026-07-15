import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One arc of a [DonutChart]: its magnitude and the color it's drawn in.
typedef DonutSlice = ({double value, Color color});

/// A donut/ring chart built with [CustomPainter] — no charting dependency.
///
/// Slices are drawn clockwise starting at 12 o'clock, proportional to
/// `value / total`. A single slice renders as a full, rounded-cap ring; two or
/// more slices get a small angular gap between them so segments read as
/// distinct even at low contrast. [center] overlays a widget (e.g. the
/// month's total) in the middle of the ring.
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.slices,
    this.size = 160,
    this.strokeWidth = 22,
    this.center,
    super.key,
  });

  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(slices: slices, strokeWidth: strokeWidth),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.strokeWidth});

  final List<DonutSlice> slices;
  final double strokeWidth;

  /// Angular gap between adjacent slices, in radians (~2°).
  static const double _gap = 2 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    const start = -math.pi / 2;
    final singleSlice = slices.length == 1;

    var angle = start;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = slice.value / total * 2 * math.pi;
      final effectiveSweep = singleSlice
          ? sweep
          : (sweep - _gap).clamp(0.0, sweep);

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = singleSlice ? StrokeCap.round : StrokeCap.butt;

      canvas.drawArc(inset, angle, effectiveSweep, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.strokeWidth != strokeWidth;
}
