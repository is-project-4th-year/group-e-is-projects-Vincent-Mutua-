import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String text;

  const AuthHeader({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // We use the headlineLarge style from our theme.
      // This will automatically be Inclusive Sans.
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}