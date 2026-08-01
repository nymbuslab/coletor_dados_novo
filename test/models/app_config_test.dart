import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/app_config.dart';

void main() {
  group('AppConfig', () {
    test('construtor vazio define valores padrão', () {
      final config = AppConfig.empty();
      expect(config.endereco, '');
      expect(config.porta, '');
      expect(config.licenca, '');
      expect(config.isConfigured, false);
    });

    test('toMap e fromMap são inversos', () {
      final original = AppConfig(
        endereco: '192.168.1.100',
        porta: '8080',
        licenca: 'ABC-123',
        isConfigured: true,
      );
      final map = original.toMap();
      final restored = AppConfig.fromMap(map);

      expect(restored.endereco, original.endereco);
      expect(restored.porta, original.porta);
      expect(restored.licenca, original.licenca);
      expect(restored.isConfigured, original.isConfigured);
    });

    test('fromMap com campos ausentes usa valores padrão', () {
      final config = AppConfig.fromMap({});
      expect(config.endereco, '');
      expect(config.porta, '');
      expect(config.licenca, '');
      expect(config.isConfigured, false);
    });

    test('copyWith atualiza apenas campos especificados', () {
      final original = AppConfig(
        endereco: '192.168.1.1',
        porta: '3000',
        licenca: 'LIC-001',
      );
      final copy = original.copyWith(porta: '9090', isConfigured: true);

      expect(copy.endereco, '192.168.1.1');
      expect(copy.porta, '9090');
      expect(copy.licenca, 'LIC-001');
      expect(copy.isConfigured, true);
    });

    test('copyWith sem argumentos retorna objeto idêntico', () {
      final original = AppConfig(
        endereco: '10.0.0.1',
        porta: '8000',
        licenca: 'XYZ',
        isConfigured: true,
      );
      final copy = original.copyWith();

      expect(copy.endereco, original.endereco);
      expect(copy.porta, original.porta);
      expect(copy.licenca, original.licenca);
      expect(copy.isConfigured, original.isConfigured);
    });

    test('toString contém os campos principais', () {
      final config = AppConfig(
        endereco: '10.0.0.1',
        porta: '8080',
        licenca: 'LIC',
        isConfigured: true,
      );
      final s = config.toString();
      expect(s, contains('10.0.0.1'));
      expect(s, contains('8080'));
      expect(s, contains('LIC'));
    });
  });
}
