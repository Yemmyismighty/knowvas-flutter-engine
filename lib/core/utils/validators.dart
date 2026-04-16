/// Input validators for form fields and user input
/// 
/// Provides validation functions for common input types including
/// email, password, username, and other user-provided data.
class Validators {
  Validators._();

  /// Validate email address format
  /// 
  /// Returns error message if invalid, null if valid
  /// 
  /// Rules:
  /// - Must not be empty
  /// - Must match standard email format
  /// - Must have valid domain
  /// 
  /// Example:
  /// ```dart
  /// final error = Validators.validateEmail('user@example.com');
  /// if (error != null) {
  ///   print('Invalid email: $error');
  /// }
  /// ```
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    // Trim whitespace
    final trimmed = email.trim();

    // Check minimum length
    if (trimmed.length < 3) {
      return 'Email is too short';
    }

    // Check maximum length (RFC 5321)
    if (trimmed.length > 254) {
      return 'Email is too long';
    }

    // Email regex pattern
    // Matches: user@domain.com, user.name@domain.co.uk, etc.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    // Check for consecutive dots
    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }

    // Check for valid domain
    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }

    final domain = parts[1];
    if (!domain.contains('.')) {
      return 'Email must have a valid domain';
    }

    return null;
  }

  /// Validate password strength
  /// 
  /// Returns error message if invalid, null if valid
  /// 
  /// Rules:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character (optional, configurable)
  /// 
  /// Example:
  /// ```dart
  /// final error = Validators.validatePassword('MyP@ssw0rd');
  /// ```
  static String? validatePassword(
    String? password, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumber = true,
    bool requireSpecialChar = false,
  }) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    // Check minimum length
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    // Check maximum length (prevent DoS)
    if (password.length > 128) {
      return 'Password is too long (max 128 characters)';
    }

    // Check for uppercase letter
    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (requireNumber && !password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    if (requireSpecialChar &&
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password',
      '12345678',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
    ];

    if (weakPasswords.contains(password.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Validate password confirmation matches original password
  /// 
  /// Returns error message if passwords don't match, null if they match
  static String? validatePasswordConfirmation(
    String? password,
    String? confirmation,
  ) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmation) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate username
  /// 
  /// Returns error message if invalid, null if valid
  /// 
  /// Rules:
  /// - 3-30 characters
  /// - Alphanumeric, underscore, and hyphen only
  /// - Must start with a letter
  /// - Cannot end with underscore or hyphen
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }

    final trimmed = username.trim();

    // Check length
    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (trimmed.length > 30) {
      return 'Username must be at most 30 characters';
    }

    // Check format: alphanumeric, underscore, hyphen
    final usernameRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return 'Username must start with a letter and contain only letters, numbers, underscores, and hyphens';
    }

    // Check for consecutive special characters
    if (trimmed.contains('__') ||
        trimmed.contains('--') ||
        trimmed.contains('_-') ||
        trimmed.contains('-_')) {
      return 'Username cannot contain consecutive special characters';
    }

    return null;
  }

  /// Validate name (first name, last name)
  /// 
  /// Returns error message if invalid, null if valid
  /// 
  /// Rules:
  /// - 1-50 characters
  /// - Letters, spaces, hyphens, and apostrophes only
  /// - Cannot start or end with space
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.isEmpty) {
      return '$fieldName is required';
    }

    final trimmed = name.trim();

    // Check length
    if (trimmed.isEmpty) {
      return '$fieldName cannot be empty';
    }

    if (trimmed.length > 50) {
      return '$fieldName must be at most 50 characters';
    }

    // Check format: letters, spaces, hyphens, apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    // Check for consecutive spaces
    if (trimmed.contains('  ')) {
      return '$fieldName cannot contain consecutive spaces';
    }

    return null;
  }

  /// Validate phone number
  /// 
  /// Returns error message if invalid, null if valid
  /// 
  /// Accepts various formats:
  /// - +1234567890
  /// - (123) 456-7890
  /// - 123-456-7890
  /// - 1234567890
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }

    // Remove common formatting characters
    final digitsOnly = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check if only digits remain
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return 'Phone number can only contain digits and formatting characters';
    }

    // Check length (10-15 digits for international numbers)
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Phone number must be between 10 and 15 digits';
    }

    return null;
  }

  /// Validate URL
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateURL(String? url) {
    if (url == null || url.isEmpty) {
      return 'URL is required';
    }

    final trimmed = url.trim();

    // URL regex pattern
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(trimmed)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Validate required field (generic)
  /// 
  /// Returns error message if empty, null if has value
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  /// 
  /// Returns error message if too short, null if valid
  static String? validateMinLength(
    String? value,
    int minLength, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  /// 
  /// Returns error message if too long, null if valid
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'Field',
  }) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }

    return null;
  }

  /// Validate numeric input
  /// 
  /// Returns error message if not a valid number, null if valid
  static String? validateNumeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }

  /// Validate integer input
  /// 
  /// Returns error message if not a valid integer, null if valid
  static String? validateInteger(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (int.tryParse(value) == null) {
      return '$fieldName must be a valid integer';
    }

    return null;
  }

  /// Validate range (numeric)
  /// 
  /// Returns error message if out of range, null if valid
  static String? validateRange(
    String? value,
    double min,
    double max, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validate credit card number (basic Luhn algorithm check)
  /// 
  /// Returns error message if invalid, null if valid
  /// 
  /// Note: This is a basic validation. For production, use a proper
  /// payment gateway that handles PCI compliance.
  static String? validateCreditCard(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) {
      return 'Card number is required';
    }

    // Remove spaces and hyphens
    final digitsOnly = cardNumber.replaceAll(RegExp(r'[\s\-]'), '');

    // Check if only digits
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return 'Card number can only contain digits';
    }

    // Check length (13-19 digits for most cards)
    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Invalid card number length';
    }

    // Luhn algorithm check
    if (!_luhnCheck(digitsOnly)) {
      return 'Invalid card number';
    }

    return null;
  }

  /// Luhn algorithm for credit card validation
  static bool _luhnCheck(String cardNumber) {
    var sum = 0;
    var alternate = false;

    for (var i = cardNumber.length - 1; i >= 0; i--) {
      var digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validate date format (YYYY-MM-DD)
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Date is required';
    }

    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(date)) {
      return 'Date must be in YYYY-MM-DD format';
    }

    // Try to parse the date
    try {
      DateTime.parse(date);
    } catch (e) {
      return 'Invalid date';
    }

    return null;
  }

  /// Combine multiple validators
  /// 
  /// Returns the first error message encountered, or null if all pass
  /// 
  /// Example:
  /// ```dart
  /// final error = Validators.combine([
  ///   () => Validators.validateRequired(value),
  ///   () => Validators.validateMinLength(value, 8),
  ///   () => Validators.validateMaxLength(value, 128),
  /// ]);
  /// ```
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
