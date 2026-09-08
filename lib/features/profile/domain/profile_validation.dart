abstract final class ProfileValidation {
  static String normalizeUsername(String value) => value.trim().toLowerCase();

  static String? username(String value) {
    final normalized = normalizeUsername(value);
    if (normalized.length < 3 || normalized.length > 24) {
      return 'Use entre 3 e 24 caracteres.';
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9._]{1,22}[a-z0-9]$').hasMatch(normalized)) {
      return 'Use letras minúsculas, números, ponto ou underline, sem começar ou terminar com símbolo.';
    }
    return null;
  }

  static String? displayName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Informe seu nome.';
    if (normalized.length > 60) return 'Use no máximo 60 caracteres.';
    return null;
  }

  static String? bio(String value) {
    if (value.length > 160) return 'Use no máximo 160 caracteres.';
    return null;
  }
}
