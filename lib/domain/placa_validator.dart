abstract final class PlacaValidator {
  static final RegExp _mercosul = RegExp(r'^[A-Z]{3}\d[A-Z]\d{2}$');
  static final RegExp _antiga = RegExp(r'^[A-Z]{3}\d{4}$');
  static final RegExp _separadores = RegExp(r'[\s\-\.]');

  static String normalize(String raw) =>
      raw.replaceAll(_separadores, '').toUpperCase();

  static bool isValid(String normalized) =>
      _mercosul.hasMatch(normalized) || _antiga.hasMatch(normalized);

  /// Devolve null quando a placa é válida, caso contrário mensagem em pt-BR
  /// apropriada para exibir num form.
  static String? validate(String raw) {
    final n = normalize(raw);
    if (n.isEmpty) return 'Informe a placa';
    if (n.length != 7) return 'Placa deve ter 7 caracteres';
    if (!isValid(n)) return 'Formato inválido (ex.: ABC1D23 ou ABC1234)';
    return null;
  }
}
