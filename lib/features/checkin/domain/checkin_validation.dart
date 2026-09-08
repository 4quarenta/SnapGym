abstract final class CheckinValidation {
  static String? duration(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) return 'Informe a duração em minutos.';
    if (value < 1 || value > 720) {
      return 'A duração deve ficar entre 1 e 720 minutos.';
    }
    return null;
  }

  static String? note(String raw) {
    if (raw.trim().length > 280) {
      return 'A observação deve ter no máximo 280 caracteres.';
    }
    return null;
  }
}
