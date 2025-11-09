import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  late Timer _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Start a timer to check for verification every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    // ALWAYS cancel timers in dispose()
    _timer.cancel();
    super.dispose();
  }

  /// Checks with Firebase if the user's email is verified.
  Future<void> _checkEmailVerified() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      _timer.cancel(); // Stop checking if user is null
      return;
    }

    // Crucial step:
    // Firebase caches the user, so we MUST reload to get the latest status.
    await user.reload();

    if (user.emailVerified) {
      _timer.cancel();
      // The user is now verified. The AuthWrapper will automatically
      // see the new state from authStateProvider and navigate to HomeScreen.
      // We don't even need to manually navigate!
    }
  }

  /// Resends the verification email.
  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      
      // The await pause happens here
      await user?.sendEmailVerification();

      // FIX: Check if the widget is still mounted before using 'context'
      if (!mounted) return; 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      // Also check mounted before using context inside the catch block
      if (!mounted) return; 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      // We can safely call setState here without 'mounted' check
      // because finally is guaranteed to run after the try/catch blocks
      // but 'setState' itself has an implicit check.
      if (mounted) {
         setState(() => _isResending = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Get the user's email to display it
    final userEmail = ref.watch(firebaseAuthProvider).currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'A verification link has been sent to:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                userEmail ?? 'your email address',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 32),
              Text(
                'Please check your inbox (and spam folder) and click the link to verify your account.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // "Resend Email" Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  child: _isResending
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text('Resend Email'),
                ),
              ),
              const SizedBox(height: 16),

              // "Cancel" (Logout) Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _timer.cancel();
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  // Style to look less important (e.g., as a text button)
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Cancel and Log Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}