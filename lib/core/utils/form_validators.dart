class FormValidators {
  static String? required(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? fullName(String? value) {
    final requiredMessage = required(value, fieldName: 'Full name');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final parts = value!.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Enter at least a first name and last name.';
    }

    return null;
  }

  static String? personName(String? value, {required String fieldName}) {
    final requiredMessage = required(value, fieldName: fieldName);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final trimmed = value!.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters.';
    }

    return null;
  }

  static String? username(String? value) {
    final requiredMessage = required(value, fieldName: 'Username');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final trimmed = value!.trim();
    if (trimmed.length < 4) {
      return 'Username must be at least 4 characters.';
    }

    final isValid = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed);
    if (!isValid) {
      return 'Username can use only letters, numbers, and underscores.';
    }

    return null;
  }

  static String? email(String? value) {
    final requiredMessage = required(value, fieldName: 'Email');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final trimmed = value!.trim();
    final isValid = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(trimmed);

    if (!isValid) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? phoneNumber(String? value) {
    final requiredMessage = required(value, fieldName: 'Telephone number');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final trimmed = value!.trim();
    final isValid = RegExp(r'^\+?[0-9]{10,15}$').hasMatch(trimmed);

    if (!isValid) {
      return 'Enter a valid telephone number with 10 to 15 digits.';
    }

    return null;
  }

  static String? password(String? value) {
    final requiredMessage = required(value, fieldName: 'Password');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final password = value!;
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);

    if (!hasUppercase || !hasLowercase || !hasDigit) {
      return 'Password must include uppercase, lowercase, and a number.';
    }

    return null;
  }

  static String? confirmPassword(String? value, {required String password}) {
    final requiredMessage = required(value, fieldName: 'Confirm password');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (value != password) {
      return 'Passwords do not match.';
    }

    return null;
  }
}
