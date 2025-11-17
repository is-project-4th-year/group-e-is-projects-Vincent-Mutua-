import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/presentation/auth/ui/screens/loading_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/login_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/signup_details_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/signup_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/verification_screen.dart';
import 'package:is_application/presentation/journal/ui/screens/journal_editor_screen.dart';
import 'package:is_application/presentation/profile/ui/screens/profile_screen.dart';
import 'package:is_application/core/routing/app_shell.dart';
import 'package:is_application/presentation/home/ui/screens/home_screen.dart';
import 'package:is_application/presentation/tasks/ui/screens/tasks_screen.dart';
import 'package:is_application/presentation/journal/ui/screens/journal_screen.dart';

// 1. FIX: Import the FocusScreen
import 'package:is_application/presentation/focus/ui/screens/focus_screen.dart';

// 2. Define your route paths as constants
class AppRoutes {
  static const String loading = '/loading';
  static const String signUp = '/signup';
  static const String signUpDetails = '/signup-details';
  static const String verifyEmail = '/verify-email';
  static const String login = '/login';
  
  // Shell routes
  static const String home = '/';
  static const String tasks = '/tasks';
  static const String journal = '/journal';
  
  // 2. FIX: Add the Focus route constant
  static const String focus = '/focus';
  
  // Top-level sub-page
  static const String journalEditor = '/journal-editor';
  static const String profile = '/profile';
}

// Create the GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.loading,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      // ... (Your redirect logic is correct and does not need to change)
      final location = state.matchedLocation;
      if (authState.isLoading || !authState.hasValue) {
        return AppRoutes.loading;
      }
      final user = authState.value;
      if (user == null) {
        final isAuthRoute = location == AppRoutes.login ||
            location == AppRoutes.signUp ||
            location == AppRoutes.signUpDetails;
        return isAuthRoute ? null : AppRoutes.signUp;
      }
      if (!user.emailVerified) {
        return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      }
      final isAuthPage = location == AppRoutes.login ||
          location == AppRoutes.signUp ||
          location == AppRoutes.signUpDetails ||
          location == AppRoutes.verifyEmail ||
          location == AppRoutes.loading;
      return isAuthPage ? AppRoutes.home : null;
    },

    // 4. Define all your app's routes
    routes: [
      // Auth/Loading Routes (No Shell)
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUpDetails,
        builder: (context, state) {
          final email = state.extra as String;
          return SignUpDetailsScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.journalEditor,
        builder: (context, state) => const JournalEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // --- StatefulShellRoute for Persistent Bottom Navigation ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
            ],
          ),
          
          // Branch 1 (Tasks)
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.tasks, builder: (context, state) => const TasksScreen()),
            ],
          ),
          
          // Branch 2 (Journal)
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.journal, builder: (context, state) => const JournalScreen()),
            ],
          ),
          
          // 3. FIX: Add the 4th Branch for the Focus Screen
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.focus, builder: (context, state) => const FocusScreen()),
            ],
          ),
        ],
      ), 
      // --- End of ShellRoute ---
    ],
  );
});