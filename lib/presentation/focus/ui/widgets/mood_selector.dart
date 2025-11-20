import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/focus/providers/focus_session_provider.dart';
import 'package:is_application/presentation/focus/services/spotify_service.dart';
import 'package:is_application/presentation/focus/ui/widgets/music_visualizer.dart';

class MoodSelector extends ConsumerWidget {
  const MoodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(focusSessionProvider);
    final notifier = ref.read(focusSessionProvider.notifier);
    final spotifyService = SpotifyService();

    return Column(
      children: [
        // Mood Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: FocusMood.values.map((mood) {
                final isSelected = sessionState.selectedMood == mood;
                return GestureDetector(
                  onTap: () => notifier.setMood(mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      mood.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // Spotify Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 140, // Fixed height for the card
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(spotifyService.getMoodImageUrl(sessionState.selectedMood)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), // Darken image for text readability
                BlendMode.darken,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Visualizer Overlay (Bottom)
              Positioned(
                bottom: 10,
                left: 20,
                right: 80, // Leave space for play button
                child: MusicVisualizer(
                  color: Colors.white,
                  barCount: 20,
                  height: 30,
                  isPlaying: sessionState.isMusicPlaying,
                ),
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Toggle Music State
                    notifier.toggleMusic();
                    
                    // If turning ON, launch Spotify
                    if (!sessionState.isMusicPlaying) {
                      spotifyService.launchSpotify(sessionState.selectedMood);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Album Art / Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        
                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                spotifyService.getMoodName(sessionState.selectedMood),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                spotifyService.getMoodDescription(sessionState.selectedMood),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 20), // Space for visualizer
                            ],
                          ),
                        ),
                        
                        // Play/Pause Button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954), // Spotify Green
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Icon(
                            sessionState.isMusicPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white, 
                            size: 28
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
