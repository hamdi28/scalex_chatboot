import 'package:easy_localization/easy_localization.dart';

/// A collection of common input validation methods.
class Validators {
  /// Validates that the [value] is a valid email address.
  /// Returns an error message if invalid, otherwise `null`.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'error_invalid_email'.tr();
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'error_invalid_email'.tr();
    }

    return null;
  }

  /// Validates that the [value] is a strong enough password.
  /// Returns an error message if invalid, otherwise `null`.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'error_weak_password'.tr();
    }

    if (value.length < 6) {
      return 'error_weak_password'.tr();
    }

    return null;
  }

  /// Validates that the [value] matches the given [password].
  /// Returns an error message if they do not match, otherwise `null`.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'error_weak_password'.tr();
    }

    if (value != password) {
      return 'error_passwords_dont_match'.tr();
    }

    return null;
  }

  /// Validates that a required [value] is not empty.
  /// Returns an error message including [fieldName] if empty, otherwise `null`.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'error_field_required'.tr(namedArgs: {'field': fieldName});
    }
    return null;
  }

  /// Validates that a message [value] is not empty or whitespace.
  /// Returns an error message if empty, otherwise `null`.
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'error_empty_message'.tr();
    }
    return null;
  }
}
