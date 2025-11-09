import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  
  // --- NEW PROPERTIES ---
  /// Set to true to treat this as a password field.
  final bool isPassword;
  
  /// The current obscured state (true = hidden, false = visible).
  final bool isObscured;
  
  /// The callback function to toggle the visibility state.
  final VoidCallback? onToggleVisibility;
  // --- END NEW PROPERTIES ---

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isPassword = false,
    this.isObscured = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          // Use the 'isObscured' state
          obscureText: isObscured, 
          decoration: InputDecoration(
            // --- NEW LOGIC for visibility icon ---
            suffixIcon: isPassword
                ? IconButton(
                    // Use the icons from your Figma mock
                    icon: Icon(
                      isObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null, // Don't show any icon if it's not a password field
          ),
        ),
      ],
    );
  }
}