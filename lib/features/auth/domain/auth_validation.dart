abstract final class AuthValidation {
  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.length < 8) return 'Use pelo menos 8 caracteres.';
    return null;
  }
}
