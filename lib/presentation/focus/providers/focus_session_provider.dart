import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// The different states a focus session can be in.
enum SessionStatus {
  initial,  // Ready to start
  running,  // Ticking down
  paused,   // Paused
  finished, // Completed successfully
}

/// The state model for our focus session.
/// We use @immutable for efficiency.
@immutable
class FocusSessionState {
  final Duration totalDuration;
  final Duration remainingDuration;
  final SessionStatus status;

  const FocusSessionState({
    required this.totalDuration,
    required this.remainingDuration,
    required this.status,
  });

  /// The default, 25-minute "Pomodoro" state.
  factory FocusSessionState.initial() {
    const defaultDuration = Duration(minutes: 25);
    return const FocusSessionState(
      totalDuration: defaultDuration,
      remainingDuration: defaultDuration,
      status: SessionStatus.initial,
    );
  }

  /// Helper to create a copy with new values.
  FocusSessionState copyWith({
    Duration? totalDuration,
    Duration? remainingDuration,
    SessionStatus? status,
  }) {
    return FocusSessionState(
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      status: status ?? this.status,
    );
  }
}

/// The Notifier that manages the session's logic and timer.
class FocusSessionNotifier extends StateNotifier<FocusSessionState> {
  Timer? _timer;

  FocusSessionNotifier() : super(FocusSessionState.initial());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Starts a new session or resumes a paused one.
  void startSession() {
    if (state.status == SessionStatus.running) return; // Already running

    // Set status to running
    state = state.copyWith(status: SessionStatus.running);

    // Start the 1-second ticker
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = state.remainingDuration - const Duration(seconds: 1);

      if (newRemaining.inSeconds <= 0) {
        // Session Finished!
        _timer?.cancel();
        state = state.copyWith(
          remainingDuration: Duration.zero,
          status: SessionStatus.finished,
        );
        // TODO: Play a sound or show a notification
      } else {
        // Ticking down
        state = state.copyWith(remainingDuration: newRemaining);
      }
    });
  }

  /// Pauses the currently running session.
  void pauseSession() {
    _timer?.cancel();
    state = state.copyWith(status: SessionStatus.paused);
  }

  /// Resets the session to its initial state.
  void resetSession() {
    _timer?.cancel();
    state = FocusSessionState.initial();
  }

  /// Sets the total duration for the *next* session.
  /// Can only be done when the timer is not running.
  void setDuration(Duration newDuration) {
    if (state.status == SessionStatus.initial ||
        state.status == SessionStatus.finished) {
      state = state.copyWith(
        totalDuration: newDuration,
        remainingDuration: newDuration,
      );
    }
  }
}

// --- The Provider ---

/// The provider that the UI will watch to get the [FocusSessionState].
final focusSessionProvider =
    StateNotifierProvider<FocusSessionNotifier, FocusSessionState>((ref) {
  return FocusSessionNotifier();
});