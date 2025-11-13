import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:is_application/core/utils/validators.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
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

  void _onNextPressed() {
    // First, validate the email format
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      // Email is available, proceed to next screen
      context.push(
        AppRoutes.signUpDetails,
        extra: email,
      );
    }
  }

  /// Handles Google Sign-In logic
  void _onGoogleSignUpPressed() {
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  /// Navigates to the Login screen
  void _onLoginPressed() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    // Get the main auth state (for Google Sign In)
    final authState = ref.watch(authControllerProvider);

    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
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
                  validator: Validators.isValidEmail,
                ),
                const SizedBox(height: 24),

                AuthButton(
                  text: 'Next',
                  isLoading: isLoading,
                  onPressed: _onNextPressed,
                ),
                const SizedBox(height: 24),

                SocialAuthButton(
                  text: 'Sign up with Google',
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