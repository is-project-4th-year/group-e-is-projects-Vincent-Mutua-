import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/focus/providers/focus_session_provider.dart';

class FocusTimerVisual extends ConsumerWidget {
  const FocusTimerVisual({super.key});

  /// Formats a Duration into a MM:SS string.
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get the current state
    final sessionState = ref.watch(focusSessionProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));

    // Calculate the progress percentage (from 1.0 down to 0.0)
    final double progress =
        sessionState.remainingDuration.inMilliseconds /
        sessionState.totalDuration.inMilliseconds;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. The Outer Container (to define the size)
        SizedBox(
          width: 300,
          height: 300,
          child: Transform(
            // Flip the circle so it drains clockwise
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ),
        
        // 2. The Digital Time (MM:SS)
        Text(
          _formatDuration(sessionState.remainingDuration),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}