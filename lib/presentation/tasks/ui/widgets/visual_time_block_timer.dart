import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class VisualTimeBlockTimer extends StatefulWidget {
  final Duration duration;
  final String taskName;
  final Color? color;
  final VoidCallback? onTimerFinished;

  const VisualTimeBlockTimer({
    super.key,
    required this.duration,
    required this.taskName,
    this.color,
    this.onTimerFinished,
  });

  @override
  State<VisualTimeBlockTimer> createState() => _VisualTimeBlockTimerState();
}

class _VisualTimeBlockTimerState extends State<VisualTimeBlockTimer> {
  late Timer _timer;
  late Duration _timeRemaining;
  late int _totalSeconds;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.duration.inSeconds;
    _timeRemaining = widget.duration;
    startTimer();
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  void startTimer() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      } else {
        _timer.cancel();
        setState(() {
          _isRunning = false;
        });
        widget.onTimerFinished?.call();
      }
    });
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  String get _formattedTime {
    final minutes = _timeRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _timeRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0.0;
    return 1.0 - (_timeRemaining.inSeconds / _totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: The Visual Timer
              SizedBox.expand(
                child: CustomPaint(
                  painter: VisualTimerPainter(
                    progress: _progress,
                    color: primaryColor,
                    trackColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              
              // Layer 2: Time and Task Name
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formattedTime,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      widget.taskName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: _isRunning ? pauseTimer : startTimer,
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class VisualTimerPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color trackColor;

  VisualTimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - 10; // Padding for stroke
    const strokeWidth = 20.0;

    // Draw 1: Circular Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw 2: Progress Arc
    // Start at -90 degrees (12 o'clock)
    // Sweep clockwise based on progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      sweepAngle,
      false, // Use center (false for stroke)
      progressPaint,
    );

    // Draw 3: Indicator Arrow/Dot (Optional)
    if (progress > 0 && progress < 1.0) {
      final endAngle = -pi / 2 + sweepAngle;
      final indicatorRadius = radius;
      
      final indicatorCenter = Offset(
        center.dx + indicatorRadius * cos(endAngle),
        center.dy + indicatorRadius * sin(endAngle),
      );

      // Draw a white dot with shadow for visibility
      canvas.drawCircle(
        indicatorCenter,
        strokeWidth / 2.5, // Slightly smaller than stroke
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VisualTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.trackColor != trackColor;
  }
}
