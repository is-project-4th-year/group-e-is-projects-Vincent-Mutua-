class Validators {
  /// A simple regex for basic email format validation.
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  /// Validates the email format.
  /// Returns an error string if invalid, or `null` if valid.
  static String? isValidEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    if (!_emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null; // Email is valid
  }

  /// Validates the password format.
  /// Returns an error string if invalid, or `null` if valid.
  static String? isValidPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null; // Password is valid
  }
}