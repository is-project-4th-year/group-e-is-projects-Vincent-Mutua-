import 'dart:math';
import 'package:flutter/material.dart';

class MusicVisualizer extends StatefulWidget {
  final Color color;
  final int barCount;
  final double height;
  final bool isPlaying;

  const MusicVisualizer({
    super.key,
    required this.color,
    this.barCount = 15,
    this.height = 50,
    this.isPlaying = true,
  });

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + _random.nextInt(500)),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutQuad),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(MusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.animateTo(0.1, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 4, // Thin modern bars
                height: widget.height * _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
