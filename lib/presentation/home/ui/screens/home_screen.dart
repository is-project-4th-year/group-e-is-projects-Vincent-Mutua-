import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/presentation/home/ui/widgets/feature_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the current Firebase user to get their name/display information
    final user = ref.watch(firebaseAuthProvider).currentUser;
    
    // Determine the user's first name for a personalized greeting
    final firstName = user?.displayName?.split(' ').first ?? 'User';

    // The user's name will automatically update here if they signed up with Google/Email
    final greetingText = 'Hello, $firstName.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          // Profile avatar - navigates to Profile screen
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: user?.photoURL != null && user!.photoURL!.isNotEmpty
                  ? NetworkImage(user.photoURL!) as ImageProvider
                  : const AssetImage('assets/icons/avatar_placeholder.png'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Call the signOut method from your AuthController
              ref.read(authControllerProvider.notifier).signOut();
              // GoRouter will automatically redirect the user to /login
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Personalized Greeting ---
              Text(
                greetingText,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to take control of your day?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),

              // --- Feature Tiles ---
              

              // 1. Tasks Feature Tile
              FeatureTile(
                title: 'Task Management',
                subtitle: 'Organize priorities and break down large tasks.',
                icon: Icons.task_alt,
                onTap: () {
                  // Use GoRouter to navigate to the Tasks feature
                  context.go(AppRoutes.tasks); 
                },
              ),
              const SizedBox(height: 16),


              // 2. Journal Feature Tile
              FeatureTile(
                title: 'Daily Journal',
                subtitle: 'Track your moods, thoughts, and progress.',
                icon: Icons.edit_note,
                onTap: () {
                  // Use GoRouter to navigate to the Journal feature
                  context.go(AppRoutes.journal);
                },
              ),
              const SizedBox(height: 16),

              // 3. Focus/Music Feature Tile (Placeholder)
              FeatureTile(
              title: 'Focus Mode',
              subtitle: 'Start a structured work session with ambient music.',
              icon: Icons.timer,
              onTap: () {
                // FIX: Use context.go() to switch to the Focus tab
                context.go(AppRoutes.focus); 
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}