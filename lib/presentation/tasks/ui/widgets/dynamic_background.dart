import 'dart:async';
import 'package:flutter/material.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;
  const DynamicBackground({super.key, required this.child});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> {
  late Timer _timer;
  late Timer _animTimer;
  late List<Color> _gradientColors;
  late Alignment _beginAlignment;
  late Alignment _endAlignment;

  @override
  void initState() {
    super.initState();
    _updateTheme();
    // Update theme every minute to check for time changes
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTheme();
    });
    
    // Initial animation values
    _beginAlignment = Alignment.topLeft;
    _endAlignment = Alignment.bottomRight;
    
    // Animate gradient direction slowly
    _animTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          if (_beginAlignment == Alignment.topLeft) {
            _beginAlignment = Alignment.topCenter;
            _endAlignment = Alignment.bottomCenter;
          } else if (_beginAlignment == Alignment.topCenter) {
            _beginAlignment = Alignment.topRight;
            _endAlignment = Alignment.bottomLeft;
          } else if (_beginAlignment == Alignment.topRight) {
             _beginAlignment = Alignment.centerRight;
             _endAlignment = Alignment.centerLeft;
          } else {
            _beginAlignment = Alignment.topLeft;
            _endAlignment = Alignment.bottomRight;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animTimer.cancel();
    super.dispose();
  }

  void _updateTheme() {
    final hour = DateTime.now().hour;
    List<Color> newColors;

    if (hour >= 5 && hour < 12) {
      // Morning: Soft Sunrise
      newColors = [
        const Color(0xFFFFF1EB), // Light Peach
        const Color(0xFFACE0F9), // Pale Blue
      ];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: Bright Day
      newColors = [
        const Color(0xFFE0C3FC), // Light Purple
        const Color(0xFF8EC5FC), // Light Blue
      ];
    } else if (hour >= 17 && hour < 20) {
      // Evening: Sunset (Calmer)
      newColors = [
        const Color(0xFFF6D365), // Soft Gold
        const Color(0xFFFDA085), // Soft Orange/Salmon
      ];
    } else {
      // Night: Deep Calm
      newColors = [
        const Color(0xFF0f2027),
        const Color(0xFF203a43),
        const Color(0xFF2c5364),
      ];
    }

    if (mounted) {
      setState(() {
        _gradientColors = newColors;
      });
    } else {
      _gradientColors = newColors;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: _beginAlignment,
          end: _endAlignment,
          colors: _gradientColors,
        ),
      ),
      child: widget.child,
    );
  }
}
