import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // NEW: Import go_router
import 'package:is_application/core/routing/app_router.dart'; // NEW: Import your routes
import 'package:is_application/core/utils/validators.dart'; // NEW: Import validators
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
// OLD: Imports for login_screen & signup_details_screen are no longer needed
import 'package:is_application/presentation/auth/ui/widgets/auth_button.dart';
import 'package:is_application/presentation/auth/ui/widgets/auth_header.dart';
import 'package:is_application/presentation/auth/ui/widgets/auth_link.dart';
import 'package:is_application/presentation/auth/ui/widgets/auth_text_field.dart';
import 'package:is_application/presentation/auth/ui/widgets/social_auth_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Navigates to the next step of sign-up
  void _onNextPressed() {
    if (_formKey.currentState!.validate()) {
      // NEW: Use context.push to navigate via go_router
      // and pass the email as 'extra'
      context.push(
        AppRoutes.signUpDetails,
        extra: _emailController.text.trim(),
      );
    }
  }

  /// Handles Google Sign-In logic
  void _onGoogleSignUpPressed() {
    // --- THIS IS THE FIX ---
    // Call the Google sign-in method from your auth provider
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  /// Navigates to the Login screen
  void _onLoginPressed() {
    // NEW: Use context.go to reset the stack and go to login
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        // NEW: Guard context use with a 'mounted' check
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(text: 'Create a free account'),
                const SizedBox(height: 48),

                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  // NEW: Use the validator from our utils file
                  validator: Validators.isValidEmail,
                ),
                const SizedBox(height: 24),

                AuthButton(
                  text: 'Next',
                  isLoading: authState.isLoading,
                  onPressed: _onNextPressed,
                ),
                const SizedBox(height: 24),

                SocialAuthButton(
                  text: 'Sign up with Google',
                  // NEW: Uncommented iconPath
                  iconPath: 'assets/icons/google_logo.svg',
                  onPressed: _onGoogleSignUpPressed,
                ),
                const SizedBox(height: 48),

                AuthLink(
                  prefixText: 'Already have an account? ',
                  linkText: 'Login',
                  onTap: _onLoginPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}