import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/presentation/auth/ui/screens/loading_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/login_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/signup_details_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/signup_screen.dart';
import 'package:is_application/presentation/auth/ui/screens/verification_screen.dart';
// import 'package:is_application/presentation/home/ui/screens/home_screen.dart';

// 1. Define your route paths as constants
class AppRoutes {
  static const String loading = '/loading';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String signUpDetails = '/signup-details';
  static const String verifyEmail = '/verify-email';
  static const String home = '/';
}

// 2. Create the GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the auth state
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.loading,
    debugLogDiagnostics: true, // Helpful for debugging

    // 3. The redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;

      // While auth state is loading, show the loading screen
      if (authState.isLoading) {
        return AppRoutes.loading;
      }

      final user = authState.value;

      // --- User is Logged Out ---
      if (user == null) {
        // If the user is trying to go anywhere *but* the auth pages,
        // redirect them to the login screen.
        final isAuthRoute = location == AppRoutes.login ||
            location == AppRoutes.signUp ||
            location == AppRoutes.signUpDetails;
        
        return isAuthRoute ? null : AppRoutes.login;
      }
      
      // --- User is Logged In ---
      
      // Check for email verification
      if (!user.emailVerified) {
        // If not verified, force them to the verification screen,
        // unless they are *already* on it.
        return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      }

      // If user is logged in AND verified,
      // send them to the home screen if they try to access
      // any auth, verification, or loading page.
      final isAuthPage = location == AppRoutes.login ||
          location == AppRoutes.signUp ||
          location == AppRoutes.signUpDetails ||
          location == AppRoutes.verifyEmail ||
          location == AppRoutes.loading;

      return isAuthPage ? AppRoutes.home : null;
    },

    // 4. Define all your app's routes
    routes: [
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
          // Pass the email from the previous screen as 'extra'
          final email = state.extra as String;
          return SignUpDetailsScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerificationScreen(),
      ),
      /*GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),*/
    ],
  );
});