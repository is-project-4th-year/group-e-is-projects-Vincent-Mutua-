import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/focus/providers/focus_session_provider.dart';
import 'package:is_application/presentation/focus/ui/widgets/focus_timer_visual.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  /// Shows the settings modal to change the duration
  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    // TODO: Build a modal sheet to select duration
    // For now, we'll just add a simple duration change
    ref.read(focusSessionProvider.notifier).setDuration(const Duration(minutes: 5));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session set to 5 minutes!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the session state to update the buttons
    final sessionState = ref.watch(focusSessionProvider);
    final notifier = ref.read(focusSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
        actions: [
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsModal(context, ref),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. The Visual Timer
            const FocusTimerVisual(),
            const SizedBox(height: 60),

            // 2. The Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // --- Reset Button ---
                TextButton(
                  onPressed: notifier.resetSession,
                  child: const Text('Reset', style: TextStyle(fontSize: 18)),
                ),

                // --- Start/Pause Button ---
                // This is the main action button. Its appearance
                // and function change based on the current state.
                ElevatedButton(
                  // Use a large, round button for the primary action
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                  ),
                  onPressed: () {
                    if (sessionState.status == SessionStatus.running) {
                      notifier.pauseSession();
                    } else {
                      notifier.startSession();
                    }
                  },
                  child: Icon(
                    sessionState.status == SessionStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 40,
                  ),
                ),
                
                // --- Spacer ---
                // We use an empty TextButton to balance the "Reset" button
                TextButton(
                  onPressed: null,
                  child: Text(
                    'Reset', 
                    style: TextStyle(fontSize: 18, color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}