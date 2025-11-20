import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpinningDisc extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  final double size;

  const SpinningDisc({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
    this.size = 120,
  });

  @override
  State<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slow rotation
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
          image: DecorationImage(
            image: const AssetImage('assets/images/vinyl_texture.png'), // Fallback or overlay if we had one
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Album Art (Clipped to circle)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Vinyl Center Hole
            Container(
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E), // Match background
                shape: BoxShape.circle,
              ),
            ),
            // Vinyl Grooves Overlay (Simulated with border)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1,
                ),
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
