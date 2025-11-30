import 'dart:math';
import 'package:flutter/material.dart';

class TiimoTimerPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;
  final Color? tickColor;

  TiimoTimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.tickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw Background Circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw Progress Arc (Pie Slice)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Sweep angle: 360 * progress
    final sweepAngle = 2 * pi * progress;

    // Draw the pie slice
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top (12 o'clock)
      sweepAngle, // Draw clockwise
      true, // Use center (pie chart style)
      progressPaint,
    );

    // --- Tiimo Style Enhancements ---

    // 1. Draw a small white dot at the end of the arc (the "leading edge")
    // Only draw if progress is > 0 and < 1
    if (progress > 0 && progress < 1.0) {
      final endAngle = -pi / 2 + sweepAngle;
      // Position the dot slightly inside the edge or on the edge
      // Let's put it at 85% of the radius to look nice inside the slice
      final dotDistance = radius * 0.85; 
      
      final dotCenter = Offset(
        center.dx + dotDistance * cos(endAngle),
        center.dy + dotDistance * sin(endAngle),
      );

      // Draw a small shadow for the dot
      canvas.drawCircle(
        dotCenter, 
        6.0, 
        Paint()..color = Colors.black.withValues(alpha: 0.1),
      );

      // Draw the white dot
      canvas.drawCircle(
        dotCenter, 
        4.0, 
        Paint()..color = Colors.white,
      );
    }

    // 2. Draw Tick Marks (Clock face style)
    // Draw 12 ticks (every 5 minutes position)
    final tColor = tickColor ?? Colors.white.withValues(alpha: 0.3);
    final tickPaint = Paint()
      ..color = tColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = -pi / 2 + (i * 2 * pi / 12);
      // Ticks are on the outer edge, inside the circle
      final outerPoint = Offset(
        center.dx + (radius - 5) * cos(angle),
        center.dy + (radius - 5) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 15) * cos(angle),
        center.dy + (radius - 15) * sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TiimoTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.tickColor != tickColor;
  }
}
