import 'dart:math' as math;
import 'package:flutter/material.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color accentColor;

  const AuroraBackground({
    super.key,
    required this.child,
    required this.baseColor,
    required this.accentColor,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Layer
        Positioned.fill(
          child: Container(color: widget.baseColor),
        ),
        // Animated Aurora Layer
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _AuroraPainter(
                  progress: _controller.value,
                  color: widget.accentColor,
                ),
              );
            },
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AuroraPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08) // Very subtle opacity for premium feel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80); // Heavy blur

    final w = size.width;
    final h = size.height;
    final t = progress * 2 * math.pi;

    // Blob 1: Top Left moving to Center
    final x1 = w * 0.2 + math.sin(t * 0.5) * w * 0.2;
    final y1 = h * 0.2 + math.cos(t * 0.3) * h * 0.1;
    canvas.drawCircle(Offset(x1, y1), w * 0.5, paint);

    // Blob 2: Bottom Right moving up
    final x2 = w * 0.8 + math.cos(t * 0.4) * w * 0.2;
    final y2 = h * 0.8 + math.sin(t * 0.6) * h * 0.15;
    canvas.drawCircle(Offset(x2, y2), w * 0.6, paint);

    // Blob 3: Center pulsing
    final x3 = w * 0.5 + math.sin(t * 0.8) * w * 0.1;
    final y3 = h * 0.5 + math.cos(t * 0.9) * h * 0.1;
    canvas.drawCircle(Offset(x3, y3), w * 0.4 + (math.sin(t) * 50), paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
