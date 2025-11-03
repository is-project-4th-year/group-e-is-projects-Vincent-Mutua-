import 'package:flutter/material.dart';

// --- Color and Style Definitions ---
// Approximating the colors from the wireframe
const Color _kBackgroundColor = Color(0xFFEBEBEB); // Very light grey for the screen background
const Color _kCardColor = Color(0xFFD8D8D8); // Medium light grey for the central container
const Color _kInputFillColor = Color(0xFF424242); // Dark grey for the input fields
const Color _kPrimaryButtonColor = Color(0xFFD0D0D0); // Light grey for the buttons

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sign Up UI',
      home: SignUpScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 40),
              // 1. Header/Title Bar (The light grey "Sign up" container)
              _buildHeaderBar(),
              const SizedBox(height: 30),

              // 2. Central Input Card
              _buildInputCard(),
              const SizedBox(height: 40),

              // 3. "Or" Divider
              _buildOrDivider(),
              const SizedBox(height: 30),

              // 4. Social Sign-up Buttons
              _buildSocialButtons(),
              const SizedBox(height: 30),

              // 5. Primary "Next" Button
              _buildPrimaryButton(text: 'Next', onPressed: () {
                // Handle Next logic
                debugPrint('Next button tapped');
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for the "Sign up" header bar
  Widget _buildHeaderBar() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: _kPrimaryButtonColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Sign up',
        style: TextStyle(
          color: Color(0xFF212121), // Dark text color
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper method for the main form card
  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _InputField(
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 25),
          _InputField(
            label: 'Password',
            obscureText: true,
          ),
          SizedBox(height: 25),
          _InputField(
            label: 'Confirm password',
            obscureText: true,
          ),
        ],
      ),
    );
  }

  // Helper method for the "Or" divider
  Widget _buildOrDivider() {
    return const Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: Color(0xFFAAAAAA),
            thickness: 1,
            endIndent: 10,
          ),
        ),
        Text(
          'Or',
          style: TextStyle(color: Color(0xFF616161), fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFAAAAAA),
            thickness: 1,
            indent: 10,
          ),
        ),
      ],
    );
  }

  // Helper method for the social sign-up buttons
  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: _buildPrimaryButton(
            text: 'Google',
            onPressed: () {
              // Handle Google sign-up
              debugPrint('Google button tapped');
            },
            icon: const Icon(Icons.g_mobiledata, color: Colors.black, size: 30),
            // Custom sizing and margin to match wireframe look
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(right: 15),
          ),
        ),
        Expanded(
          child: _buildPrimaryButton(
            text: 'Apple',
            onPressed: () {
              // Handle Apple sign-up
              debugPrint('Apple button tapped');
            },
            icon: const Icon(Icons.apple, color: Colors.black, size: 28),
            // Custom sizing and margin to match wireframe look
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(left: 15),
          ),
        ),
      ],
    );
  }

  // Reusable button template
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    Widget? icon,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 15),
  }) {
    return Padding(
      padding: margin,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryButtonColor,
          foregroundColor: const Color(0xFF212121), // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: padding,
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(text),
                ],
              )
            : Text(text),
      ),
    );
  }
}

// Widget for the Label + Dark Input Field combination
class _InputField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;

  const _InputField({
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (e.g., "Email")
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF212121), // Dark text for label
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Dark Input Field
        TextFormField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white), // White text inside field
          decoration: InputDecoration(
            fillColor: _kInputFillColor,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none, // No border visible
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
