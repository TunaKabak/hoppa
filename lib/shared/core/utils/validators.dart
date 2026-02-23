class Validators {
  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Remove non-digit characters
    final phoneDigits = value.replaceAll(RegExp(r'\D'), '');

    if (phoneDigits.length != 10) {
      return 'Telefon numarası 10 haneli olmalıdır';
    }

    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Adres gerekli';
    }

    if (value.length < 10) {
      return 'Adres en az 10 karakter olmalıdır';
    }

    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta gerekli';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta girin';
    }

    return null;
  }

  /// Validate not empty
  static String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan boş olamaz';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'Bu alan boş olamaz';
    }

    if (value.length < minLength) {
      return 'En az $minLength karakter gerekli';
    }

    return null;
  }
}
