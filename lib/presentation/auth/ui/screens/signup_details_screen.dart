import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // FIX: Import go_router
import 'package:is_application/core/routing/app_router.dart'; // FIX: Import app routes
import 'package:is_application/core/utils/validators.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
// FIX: Remove direct import to login_screen
// import 'package:is_application/presentation/auth/ui/screens/login_screen.dart'; 
import 'package:is_application/presentation/auth/ui/widgets/auth_button.dart';
import 'package:is_application/presentation/auth/ui/widgets/auth_header.dart';
import 'package:is_application/presentation/auth/ui/widgets/auth_link.dart';
import 'package:is_application/presentation/auth/ui/widgets/auth_text_field.dart';

class SignUpDetailsScreen extends ConsumerStatefulWidget {
  /// The email passed from the previous screen.
  final String email;

  const SignUpDetailsScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<SignUpDetailsScreen> createState() =>
      _SignUpDetailsScreenState();
}

class _SignUpDetailsScreenState extends ConsumerState<SignUpDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Local state for password visibility
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Submits the form to Firebase Auth.
  void _onCreateAccountPressed() {
    // 1. Validate the form
    if (_formKey.currentState!.validate()) {
      // 2. If valid, call the sign up method
      ref.read(authControllerProvider.notifier).signUp(
            widget.email,
            _passwordController.text.trim(),
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
          );
    }
  }

  /// Navigates to the Login screen
  void _onLoginPressed() {
    // FIX: Use context.go to clear the stack and navigate to login
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Listen for errors
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        // FIX: Add 'mounted' check to prevent async gap error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // Note: You don't need to manually navigate on success.
      // Your go_router redirect logic will automatically
      // see the user is logged in (but not verified)
      // and send them to the /verify-email route.
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
                // 1. Header (Reusable)
                const AuthHeader(text: 'Create your account'),
                const SizedBox(height: 48),

                // 2. First Name
                AuthTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your first name' : null,
                ),
                const SizedBox(height: 24),

                // 3. Last Name
                AuthTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your last name' : null,
                ),
                const SizedBox(height: 24),

                // 4. Password (Reusable & Upgraded)
                AuthTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  isPassword: true,
                  isObscured: _isPasswordObscured,
                  onToggleVisibility: () {
                    // Toggles the local state
                    setState(() => _isPasswordObscured = !_isPasswordObscured);
                  },
                  validator: Validators.isValidPassword,
                ),
                const SizedBox(height: 24),

                // 5. Confirm Password (Reusable & Upgraded)
                AuthTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  isPassword: true,
                  isObscured: _isConfirmPasswordObscured,
                  onToggleVisibility: () {
                    setState(() => _isConfirmPasswordObscured =
                        !_isConfirmPasswordObscured);
                  },
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 6. "Create Account" Button (Reusable)
                AuthButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _onCreateAccountPressed,
                ),
                const SizedBox(height: 48),

                // 7. "Login" Link (Reusable)
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