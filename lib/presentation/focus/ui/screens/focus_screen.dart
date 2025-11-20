import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/focus/providers/focus_session_provider.dart';
import 'package:is_application/presentation/focus/services/spotify_service.dart';
import 'package:is_application/presentation/focus/ui/widgets/flip_clock_display.dart';
import 'package:is_application/presentation/focus/ui/widgets/mood_selector.dart';
import 'package:is_application/presentation/focus/ui/widgets/music_visualizer.dart';
import 'package:is_application/presentation/focus/ui/widgets/spinning_disc.dart';
import 'package:lottie/lottie.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  /// Shows the settings modal to change the duration
  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.read(appColorsProvider(brightness));

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.focus.card,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Set Duration", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.focus.timer)
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [5, 15, 25, 45, 60].map((minutes) {
                return ActionChip(
                  backgroundColor: colors.focus.background,
                  labelStyle: TextStyle(color: colors.focus.timer),
                  label: Text("$minutes min"),
                  onPressed: () {
                    ref.read(focusSessionProvider.notifier).setDuration(Duration(minutes: minutes));
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the session state to update the buttons
    final sessionState = ref.watch(focusSessionProvider);
    final notifier = ref.read(focusSessionProvider.notifier);
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final spotifyService = SpotifyService();

    // Determine if we are in "Zen Mode" (Full Screen Clock)
    final isZenMode = sessionState.status == SessionStatus.running || sessionState.isMusicPlaying;

    return Scaffold(
      backgroundColor: colors.focus.background, // Use new Focus Palette
      appBar: isZenMode ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.focus.timer),
        title: Text('Focus Mode', style: TextStyle(color: colors.focus.timer)),
        actions: [
          // Settings Button
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () => _showSettingsModal(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- 1. CLOCK (Smooth Transition) ---
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: isZenMode ? Alignment.center : const Alignment(0, -0.75),
            child: AnimatedScale(
              scale: isZenMode ? 1.5 : 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              child: FlipClockDisplay(duration: sessionState.remainingDuration),
            ),
          ),

          // --- 2. INPUT & MOOD SELECTOR (Normal Mode) ---
          // We slide them off screen when in Zen Mode
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            bottom: isZenMode ? -400 : 120, // Slide down off screen
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: isZenMode ? 0.0 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Focus Intent Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: sessionState.status == SessionStatus.initial || sessionState.status == SessionStatus.finished
                        ? TextField(
                            style: TextStyle(color: colors.focus.timer, fontSize: 18),
                            textAlign: TextAlign.center,
                            cursorColor: colors.focus.accent,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.3),
                              hintText: "What are you focusing on?",
                              hintStyle: TextStyle(color: colors.focus.timer.withOpacity(0.5)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: colors.focus.accent.withOpacity(0.5), width: 1),
                              ),
                            ),
                            onChanged: notifier.setIntent,
                          )
                        : Text(
                            sessionState.focusIntent.isEmpty ? "Stay Focused" : sessionState.focusIntent,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.focus.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),

                  const SizedBox(height: 40),

                  // Mood Selector
                  const MoodSelector(),
                ],
              ),
            ),
          ),

          // --- 3. CONTROLS (Always Visible but moves) ---
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: isZenMode ? const Alignment(0, 0.9) : const Alignment(0, 0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset / Stop Button
                IconButton(
                  icon: Icon(
                    sessionState.status == SessionStatus.running ? Icons.stop : Icons.refresh, 
                    color: colors.focus.timer.withOpacity(0.8), 
                    size: 32
                  ),
                  onPressed: notifier.resetSession,
                ),
                
                const SizedBox(width: 32),
                
                // Play/Pause
                GestureDetector(
                  onTap: () {
                    if (sessionState.status == SessionStatus.running) {
                      notifier.pauseSession();
                    } else {
                      notifier.startSession();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isZenMode ? 70 : 80,
                    height: isZenMode ? 70 : 80,
                    decoration: BoxDecoration(
                      color: colors.focus.timer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.focus.timer.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(
                      sessionState.status == SessionStatus.running
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: isZenMode ? 35 : 40,
                      color: colors.focus.background,
                    ),
                  ),
                ),
                
                const SizedBox(width: 32),

                // Exit Zen Mode Button (Visible only in Zen Mode)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isZenMode ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isZenMode,
                    child: IconButton(
                      icon: Icon(Icons.fullscreen_exit, color: colors.focus.timer.withOpacity(0.8), size: 32),
                      onPressed: () {
                        // Exit Zen Mode: Pause Timer & Stop Music
                        if (sessionState.status == SessionStatus.running) {
                          notifier.pauseSession();
                        }
                        if (sessionState.isMusicPlaying) {
                          notifier.toggleMusic();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 4. SPINNING DISC (Zen Mode Only) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            bottom: isZenMode ? 160 : -200, // Pop up from bottom
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isZenMode && sessionState.isMusicPlaying ? 1.0 : 0.0,
              child: SpinningDisc(
                imageUrl: spotifyService.getMoodImageUrl(sessionState.selectedMood),
                isPlaying: sessionState.isMusicPlaying,
                size: 100,
              ),
            ),
          ),

          // --- 5. MUSIC VISUALIZER (Zen Mode Only) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            bottom: isZenMode ? 180 : -100, // Slide up
            left: 40,
            right: 140, // Leave space for the disc
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isZenMode && sessionState.isMusicPlaying ? 1.0 : 0.0,
              child: MusicVisualizer(
                color: colors.focus.accent,
                barCount: 15,
                height: 50,
                isPlaying: sessionState.isMusicPlaying,
              ),
            ),
          ),

          // --- 6. Celebration Overlay ---
          if (sessionState.status == SessionStatus.finished)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json', // Confetti
                  repeat: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}