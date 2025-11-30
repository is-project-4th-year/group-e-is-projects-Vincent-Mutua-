import 'dart:async';
import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/widgets/visual_time_block_timer.dart';
import 'package:is_application/core/services/sound_service.dart'; // Import SoundService
import 'package:is_application/core/services/spotify_service.dart';
import 'package:spotify/spotify.dart' as spotify; // Alias to avoid conflict if any, though PlaybackState is unique enough usually
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:flutter_animate/flutter_animate.dart';

class TaskTimerScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskTimerScreen({super.key, required this.task});

  @override
  ConsumerState<TaskTimerScreen> createState() => _TaskTimerScreenState();
}

class _TaskTimerScreenState extends ConsumerState<TaskTimerScreen> {
  Timer? _timer;
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _hasStarted = false;


  @override
  void initState() {
    super.initState();
    // Default to 25 minutes if no duration specified
    final minutes = widget.task.durationMinutes ?? 25;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    
    // Timer does NOT start automatically anymore
  }

  void _startActivity() {
    setState(() {
      _hasStarted = true;
    });
    _startTimer();
    
    // Auto-play "Deep Focus" if user hasn't picked anything yet
    // This ensures "Start Activity" starts both timer and music
    ref.read(spotifyServiceProvider).openFocusPlaylist("Deep Focus", onError: (_) {});
  }


  @override
  void dispose() {
    _timer?.cancel();
    // Optional: Stop sound when leaving screen? 
    // For now, let's keep it playing as background focus music is often desired.
    // If you want to stop it, uncomment the line below:
    // ref.read(soundServiceProvider).stop();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        _showCompletionDialog();
      }
    });
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _completeTask() async {
    _timer?.cancel();
    
    // Mark task as completed in Firestore
    final updatedTask = widget.task.copyWith(isCompleted: true);
    await ref.read(tasksControllerProvider.notifier).updateTask(updatedTask);
    
    if (mounted) {
      // Close timer screen
      if (context.canPop()) {
        context.pop();
      }
      // If we need to close another screen (like detail), we should check if we can pop again
      // But blindly popping twice is risky. 
      // Assuming the user wants to go back to the list, one pop is usually enough if they came from the list.
      // If they came from detail, they might want to go back to detail (which updates) or list.
      // Let's stick to one pop for now to be safe, or use go_router to go to home.
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Time's Up!"),
        content: const Text("Great job focusing. Do you want to mark this task as done?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Just close timer, don't complete
              context.pop(); 
            },
            child: const Text("Not yet"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _completeTask();
            },
            child: const Text("Mark Done"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showFocusSounds() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
                  children: [
                    const Text(
                      "Spotify Focus",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildSpotifySection(),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      "Soundscapes",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildSoundCard("Brown Noise", Icons.waves, Colors.brown),
                        _buildSoundCard("Rainy Mood", Icons.water_drop, Colors.blueGrey),
                        _buildSoundCard("Lo-Fi Beats", Icons.headphones, Colors.purple),
                        _buildSoundCard("Forest Ambience", Icons.forest, Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundCard(String title, IconData icon, Color color) {
    final soundService = ref.watch(soundServiceProvider);
    
    return StreamBuilder<bool>(
      stream: soundService.playingStream,
      builder: (context, snapshot) {
        final isPlaying = soundService.isPlaying(title);
        
        return GestureDetector(
          onTap: () => soundService.playSound(title),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isPlaying ? color.withValues(alpha: 0.2) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPlaying ? color : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (!isPlaying)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPlaying ? Icons.pause_circle_filled : icon,
                    size: 32,
                    color: isPlaying ? color : Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPlaying ? color : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSpotifySection() {
    final spotifyService = ref.read(spotifyServiceProvider);
    
    return StreamBuilder<bool>(
      stream: spotifyService.authStateStream,
      initialData: spotifyService.isAuthenticated,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.music_note, size: 48, color: Color(0xFF1DB954)),
                  const SizedBox(height: 12),
                  const Text(
                    "Connect to Spotify",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Play your favorite focus playlists directly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await spotifyService.authenticate();
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Connected to Spotify!")),
                          );
                          _showFocusSounds();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Spotify connection failed")),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text("Connect Now"),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playback Controls
            StreamBuilder<spotify.PlaybackState?>(
              stream: spotifyService.playbackStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final isPlaying = state?.isPlaying ?? false;
                
                // We can't easily check active device from PlaybackState in this version,
                // so we'll provide a button to check/switch devices.
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _showDevicePicker(context, spotifyService),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.devices, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                "Playback Devices",
                                style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: () => spotifyService.skipPrevious(),
                              tooltip: "Previous",
                            ),
                            IconButton(
                              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              onPressed: () => isPlaying ? spotifyService.pause() : spotifyService.resume(),
                              tooltip: isPlaying ? "Pause" : "Resume",
                              iconSize: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: () => spotifyService.skipNext(),
                              tooltip: "Next",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                ...SpotifyService.focusPlaylists.entries.map((entry) => _buildSpotifyCard(entry.key, entry.value)),
                _buildSpotifyLibraryCard(),
              ],
            ),
          ],
        );
      }
    );
  }

  void _showDevicePicker(BuildContext context, SpotifyService spotifyService) async {
    final devices = await spotifyService.getAvailableDevices();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Device", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (devices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No active Spotify devices found. Open Spotify on a device to see it here."),
              )
            else
              ...devices.map((device) => ListTile(
                leading: Icon(
                  device.type == 'Computer' ? Icons.computer : Icons.smartphone,
                  color: (device.isActive ?? false) ? Colors.green : null,
                ),
                title: Text(device.name ?? "Unknown Device"),
                subtitle: (device.isActive ?? false) ? const Text("Active", style: TextStyle(color: Colors.green)) : null,
                onTap: () async {
                  Navigator.pop(context);
                  if (device.id != null) {
                    await spotifyService.transferPlayback(device.id!);
                  }
                },
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotifyCard(String name, String id) {
    final spotifyService = ref.read(spotifyServiceProvider);
    
    return FutureBuilder<spotify.Playlist>(
      future: spotifyService.getPlaylist(id),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data?.images?.first.url;
        
        return GestureDetector(
          onTap: () => spotifyService.openFocusPlaylist(name, onError: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(16),
              image: imageUrl != null 
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.4), 
                        BlendMode.darken
                      ),
                    )
                  : null,
              gradient: imageUrl == null ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF282828),
                  const Color(0xFF181818),
                ],
              ) : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageUrl == null)
                  const Icon(Icons.play_circle_fill, color: Colors.white, size: 32)
                else 
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                  ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSpotifyLibraryCard() {
    return GestureDetector(
      onTap: () async {
         final Uri url = Uri.parse('spotify:library');
         if (await canLaunchUrl(url)) {
           await launchUrl(url);
         } else {
           await launchUrl(Uri.parse('https://open.spotify.com/collection/playlists'), mode: LaunchMode.externalApplication);
         }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music, color: Color(0xFF1DB954), size: 32),
            SizedBox(height: 8),
            Text(
              "My Library",
              style: TextStyle(
                color: Color(0xFF1DB954),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusSoundsPill(TasksPalette tasksPalette) {
    final spotifyService = ref.watch(spotifyServiceProvider);
    
    return StreamBuilder<spotify.PlaybackState?>(
      stream: spotifyService.playbackStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isPlaying = state?.isPlaying ?? false;
        final trackName = state?.item?.name;
        final artistName = state?.item?.artists?.first.name;
        
        String label = "Focus Sounds";
        if (trackName != null && trackName != "Loading...") {
          label = "$trackName • $artistName";
        } else if (isPlaying) {
          label = "Playing on Spotify...";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          constraints: const BoxConstraints(maxWidth: 340),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: tasksPalette.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: tasksPalette.textSecondary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Left side: Icon or Visualizer + Text (Clickable to open sheet)
                    Expanded(
                      child: GestureDetector(
                        onTap: _showFocusSounds,
                        child: Container(
                          color: Colors.transparent, // Hit test
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              if (isPlaying) 
                                _buildAnimatedMusicVisualizer(tasksPalette.accent)
                              else
                                Icon(Icons.music_note_rounded, size: 20, color: tasksPalette.textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isPlaying ? "Now Playing" : "Focus Sounds",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: tasksPalette.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: tasksPalette.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Right side: Play/Pause Button (if track is loaded or playing)
                    if (trackName != null || isPlaying) ...[
                      const SizedBox(width: 8),
                      Container(
                        height: 32,
                        width: 1,
                        color: tasksPalette.textSecondary.withValues(alpha: 0.2),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        color: tasksPalette.textPrimary,
                        iconSize: 24,
                        onPressed: () {
                          if (isPlaying) {
                            spotifyService.pause();
                          } else {
                            spotifyService.resume();
                          }
                        },
                      ),
                    ] else ...[
                       IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        color: tasksPalette.textSecondary,
                        onPressed: _showFocusSounds,
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildAnimatedMusicVisualizer(Color color) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildVisualizerBar(color, 0),
          const SizedBox(width: 3),
          _buildVisualizerBar(color, 1),
          const SizedBox(width: 3),
          _buildVisualizerBar(color, 2),
          const SizedBox(width: 3),
          _buildVisualizerBar(color, 3),
        ],
      ),
    );
  }

  Widget _buildVisualizerBar(Color color, int index) {
    final durations = [600, 800, 500, 700];
    
    return Container(
      width: 4,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      delay: Duration(milliseconds: index * 100),
    ).scaleY(
       begin: 0.3, 
       end: 1.0, 
       duration: Duration(milliseconds: durations[index]),
       curve: Curves.easeInOut,
       alignment: Alignment.bottomCenter
     );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    // Calculate progress (1.0 to 0.0)
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

    // Determine color based on task or default accent
    final taskColor = widget.task.color != null 
        ? Color(widget.task.color!) 
        : tasksPalette.accent;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _timer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: tasksPalette.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down, color: tasksPalette.textPrimary, size: 32),
            onPressed: _stopTimer,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: tasksPalette.accent),
              onPressed: _completeTask,
              tooltip: "Complete Task Early",
            )
          ],
        ),
        body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // --- Task Info ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        widget.task.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: tasksPalette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.task.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: taskColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.task.category!.toUpperCase(),
                          style: TextStyle(
                            color: taskColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // --- The Tiimo Timer ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // The Visual Timer
                        SizedBox(
                          width: 300,
                          height: 300,
                          child: CustomPaint(
                            painter: VisualTimerPainter(
                              progress: progress,
                              color: taskColor,
                              trackColor: tasksPalette.surface,
                            ),
                          ),
                        ),
                        // The Digital Time
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: tasksPalette.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              !_hasStarted 
                                  ? "READY" 
                                  : (_isRunning ? "FOCUSING" : "PAUSED"),
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: 2.0,
                                color: tasksPalette.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // --- Controls ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Column(
                        children: [
                          // Focus Sounds Button
                          _buildFocusSoundsPill(tasksPalette),

                          if (!_hasStarted)
                            GestureDetector(
                              onTap: _startActivity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                                decoration: BoxDecoration(
                                  color: tasksPalette.textPrimary,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tasksPalette.textPrimary.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: tasksPalette.background, size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Start Activity",
                                      style: TextStyle(
                                        color: tasksPalette.background,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Play / Pause Button
                                GestureDetector(
                                  onTap: _isRunning ? _pauseTimer : _startTimer,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: tasksPalette.textPrimary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      _isRunning ? Icons.pause : Icons.play_arrow,
                                      color: tasksPalette.background,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
      ),
    );
  }
}
