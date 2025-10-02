class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'error_invalid_email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'error_invalid_email';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'error_weak_password';
    }

    if (value.length < 6) {
      return 'error_weak_password';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'error_weak_password';
    }

    if (value != password) {
      return 'error_passwords_dont_match';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'error_empty_message';
    }
    return null;
  }
}