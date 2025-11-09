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


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  // --- UPDATE THIS METHOD ---
  /// Handles Google Sign-In logic
  void _onGoogleSignInPressed() {
    // Call the new provider method
    ref.read(authControllerProvider.notifier).signInWithGoogle();
    
    // Remove the old SnackBar
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Google Sign-In not implemented yet.')),
    // );
  }
  // --- END OF UPDATE ---

  void _onSignUpPressed() {
    context.push(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
                const AuthHeader(text: 'Login to your account'),
                const SizedBox(height: 48),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.isValidEmail,
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  isPassword: true,
                  isObscured: _isPasswordObscured,
                  onToggleVisibility: () {
                    setState(() => _isPasswordObscured = !_isPasswordObscured);
                  },
                  validator: Validators.isValidPassword,
                ),
                const SizedBox(height: 32),
                AuthButton(
                  text: 'Login',
                  isLoading: authState.isLoading,
                  onPressed: _onLoginPressed,
                ),
                const SizedBox(height: 24),
                SocialAuthButton(
                  text: 'Sign in with Google',
                  iconPath: 'assets/icons/google_logo.svg',
                  onPressed: _onGoogleSignInPressed, // Now fully functional
                ),
                const SizedBox(height: 48),
                AuthLink(
                  prefixText: "Don't have an account? ",
                  linkText: 'Sign up',
                  onTap: _onSignUpPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}