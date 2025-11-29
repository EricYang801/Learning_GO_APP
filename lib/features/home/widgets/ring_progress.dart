import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RingProgress extends StatelessWidget {
  final double ratio; // 0..1
  final bool goalReached;
  final String centerText;
  final bool dimmed;
  const RingProgress({
    super.key,
    required this.ratio,
    required this.goalReached,
    required this.centerText,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(ratio, goalReached, dimmed),
      child: SizedBox(
        width: 96,
        height: 96,
        child: Center(child: Text(centerText, textAlign: TextAlign.center)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ratio;
  final bool goal;
  final bool dim;
  _RingPainter(this.ratio, this.goal, this.dim);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = (dim ? Colors.grey.shade300 : Colors.grey.shade400);
    canvas.drawCircle(c, r, base);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = goal ? AppColors.gold : AppColors.green;

    final sweep = 2 * pi * (ratio.clamp(0, 1.0));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      sweep,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio || old.goal != goal || old.dim != dim;
}
