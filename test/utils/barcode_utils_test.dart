import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/utils/barcode_utils.dart';

void main() {
  group('BarcodeUtils.sanitize', () {
    test('remove espaços ao redor', () {
      expect(BarcodeUtils.sanitize('  1234567890  '), '1234567890');
    });

    test('remove tabs e quebras de linha', () {
      expect(BarcodeUtils.sanitize('123\t456\n789\r000'), '123456789000');
    });

    test('remove caracteres de controle (\\x00 - \\x1F)', () {
      expect(BarcodeUtils.sanitize('123\x00456\x1F789'), '123456789');
    });

    test('remove DEL (\\x7F)', () {
      expect(BarcodeUtils.sanitize('123\x7F456'), '123456');
    });

    test('mantém dígitos e letras', () {
      expect(BarcodeUtils.sanitize('ABC123xyz'), 'ABC123xyz');
    });

    test('string vazia retorna vazia', () {
      expect(BarcodeUtils.sanitize(''), '');
    });

    test('string com apenas espaços retorna vazia', () {
      expect(BarcodeUtils.sanitize('   '), '');
    });

    test('código de barras EAN-13 sem modificações permanece igual', () {
      expect(BarcodeUtils.sanitize('7891234567890'), '7891234567890');
    });

    test('normaliza código com espaços internos', () {
      expect(BarcodeUtils.sanitize('789 123 4567890'), '7891234567890');
    });
  });
}
