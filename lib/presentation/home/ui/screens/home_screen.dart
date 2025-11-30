import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/core/routing/app_router.dart';

import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/home/ui/widgets/pending_task_card.dart';
import 'package:is_application/presentation/home/ui/widgets/analytics_preview_card.dart';

import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/core/widgets/aurora_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the current Firebase user to get their name/display information
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    
    // Determine the user's first name for a personalized greeting
    final firstName = user?.displayName?.split(' ').first ?? 'User';

    // The user's name will automatically update here if they signed up with Google/Email
    final greetingText = 'Hello, $firstName.';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              context.push(AppRoutes.profile);
            },
          ),
        ],
      ),
      body: AuroraBackground(
        baseColor: appColors.background,
        accentColor: appColors.primary,
        child: SafeArea(
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

                // --- Pending Task Card ---
                Consumer(
                  builder: (context, ref, child) {
                    final tasksAsync = ref.watch(tasksProvider);
                    return tasksAsync.when(
                      data: (tasks) {
                        // Filter pending tasks
                        final pending = tasks.where((t) => !t.isCompleted).toList();
                        
                        if (pending.isEmpty) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "All caught up!",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "No pending tasks for today.",
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Sort by Priority (High > Medium > Low) then Due Date
                        pending.sort((a, b) {
                          if (a.priority != b.priority) {
                            return b.priority.index.compareTo(a.priority.index); // High index is higher priority
                          }
                          final dateA = a.dueDate?.toDate() ?? DateTime(2100);
                          final dateB = b.dueDate?.toDate() ?? DateTime(2100);
                          return dateA.compareTo(dateB);
                        });

                        return Column(
                          children: [
                            PendingTaskCard(task: pending.first),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),

                // --- Dashboard Analytics ---
                const AnalyticsPreviewCard(),

              ],
            ),
          ),
        ),
      ),
    );
  }
}