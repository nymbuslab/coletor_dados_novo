import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nymbus_coletor/models/app_config.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/license_service.dart';
import 'package:nymbus_coletor/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSecureStorage implements SecureStorageAdapter {
  final Map<String, String?> store = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => store[key];

  @override
  Future<void> delete({required String key}) async => store.remove(key);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.setSecureStorageAdapter(_FakeSecureStorage());
    ApiService.instance.setClient(
      MockClient((_) async => http.Response('ok', 200)),
    );
    ApiService.instance.configure('http://test.local');
    ApiService.instance.invalidarCache();
  });

  group('ConfigProvider.init', () {
    test('gera licença e permanece não-configurado sem config salva', () async {
      final provider = ConfigProvider();
      await provider.init();

      expect(provider.isConfigured, false);
      expect(LicenseService.isValidLicenseFormat(provider.config.licenca), true);
    });

    test('carrega config salva e a licença do secure storage', () async {
      await StorageService.saveConfig(
        AppConfig(
          endereco: 'host',
          porta: '1',
          licenca: '4321',
          isConfigured: true,
        ),
      );

      final provider = ConfigProvider();
      await provider.init();

      expect(provider.config.endereco, 'host');
      expect(provider.isConfigured, true);
      expect(provider.config.licenca, '4321');
    });
  });

  group('ConfigProvider.saveConfig', () {
    test('salva, atualiza estado e notifica listeners', () async {
      final provider = ConfigProvider();
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      final ok = await provider.saveConfig(
        endereco: '1.1.1.1',
        porta: '9000',
        licenca: '1234',
      );

      expect(ok, true);
      expect(provider.config.endereco, '1.1.1.1');
      expect(provider.isConfigured, true);
      expect(notificacoes, greaterThan(0));
    });
  });

  group('ConfigProvider.validarLicenca', () {
    test('retorna false e seta erro quando a licença está vazia, sem chamar a API', () async {
      var apiChamada = false;
      ApiService.instance.setClient(
        MockClient((_) async {
          apiChamada = true;
          return http.Response('ok', 200);
        }),
      );

      final provider = ConfigProvider(); // AppConfig.empty() → licença vazia
      final ok = await provider.validarLicenca();

      expect(ok, false);
      expect(provider.errorMessage, 'Licença não definida');
      expect(apiChamada, false);
    });

    test('retorna true e limpa erro quando o servidor valida', () async {
      ApiService.instance.setClient(
        MockClient((_) async => http.Response('ok', 200)),
      );
      final provider = ConfigProvider();
      await provider.saveConfig(endereco: 'h', porta: '1', licenca: '1234');

      final ok = await provider.validarLicenca();

      expect(ok, true);
      expect(provider.errorMessage, isNull);
    });
  });

  group('ConfigProvider.testarConectividade', () {
    test('retorna true e limpa erro quando o servidor responde', () async {
      ApiService.instance.setClient(
        MockClient((_) async => http.Response('ok', 200)),
      );
      final provider = ConfigProvider();

      final ok = await provider.testarConectividade();

      expect(ok, true);
      expect(provider.errorMessage, isNull);
    });
  });
}
