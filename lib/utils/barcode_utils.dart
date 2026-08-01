class BarcodeUtils {
  // Centralizador de sanitização de códigos de barras
  static String sanitize(String input) {
    var s = input.trim();
    s = s.replaceAll(RegExp(r'[\s\r\n\t]+'), '');
    s = s.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '');
    return s;
  }

  /// Normaliza um código para COMPARAÇÃO (não para envio).
  /// Converte UPC-A de 12 dígitos em EAN-13 acrescentando o zero à esquerda —
  /// conversão canônica e lossless (o GTIN é o mesmo), então não casa produtos
  /// diferentes. Resolve o caso do leitor que devolve 12 dígitos enquanto a base
  /// tem 13. Não altera o valor enviado à API.
  static String normalizeForCompare(String input) {
    final s = sanitize(input);
    if (s.length == 12 && RegExp(r'^\d+$').hasMatch(s)) {
      return '0$s';
    }
    return s;
  }
}
