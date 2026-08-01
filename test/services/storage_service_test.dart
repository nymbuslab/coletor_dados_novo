import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/app_config.dart';
import 'package:nymbus_coletor/models/produto.dart';
import 'package:nymbus_coletor/services/license_service.dart';
import 'package:nymbus_coletor/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage em memória, com gatilho para simular falha transitória de leitura.
class _FakeSecureStorage implements SecureStorageAdapter {
  final Map<String, String?> store = {};
  bool throwOnRead = false;

  @override
  Future<void> write({required String key, required String? value}) async {
    store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    if (throwOnRead) throw Exception('read failed (transitório)');
    return store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    store.remove(key);
  }
}

Produto _produto({
  String codBarras = '7891234567890',
  String codProduto = '100',
  String produto = 'Arroz',
  String unidade = 'UN',
}) {
  return Produto(
    codBarras: codBarras,
    codProduto: codProduto,
    produto: produto,
    unidade: unidade,
    valorVenda: 5.0,
    dataHoraRequisicao: DateTime(2025, 6, 15),
    numeroItem: 1,
  );
}

void main() {
  late _FakeSecureStorage fake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeSecureStorage();
    StorageService.setSecureStorageAdapter(fake);
  });

  group('StorageService.saveConfig / loadConfig', () {
    test('grava a licença no secure storage, não em SharedPreferences', () async {
      final ok = await StorageService.saveConfig(
        AppConfig(
          endereco: '10.0.0.9',
          porta: '8080',
          licenca: '4321',
          isConfigured: true,
        ),
      );
      expect(ok, true);

      // A licença foi para o secure storage...
      expect(fake.store['secure_license'], '4321');

      // ...e NÃO para o JSON salvo em SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('app_config')!;
      expect(raw, contains('8080'));
      expect(raw, isNot(contains('4321')));
    });

    test('loadConfig recupera a licença do secure storage', () async {
      await StorageService.saveConfig(
        AppConfig(
          endereco: 'host',
          porta: '1',
          licenca: '4321',
          isConfigured: true,
        ),
      );

      final cfg = await StorageService.loadConfig();
      expect(cfg, isNotNull);
      expect(cfg!.licenca, '4321');
      expect(cfg.endereco, 'host');
      expect(cfg.isConfigured, true);
    });

    test('loadConfig retorna null quando não há configuração salva', () async {
      expect(await StorageService.loadConfig(), isNull);
    });
  });

  group('StorageService.loadOrCreateLicense', () {
    test('retorna a licença existente sem gerar outra', () async {
      fake.store['secure_license'] = '5678';
      final lic = await StorageService.loadOrCreateLicense();
      expect(lic, '5678');
    });

    test('gera e persiste uma licença nova quando não existe', () async {
      final lic = await StorageService.loadOrCreateLicense();
      expect(LicenseService.isValidLicenseFormat(lic), true);
      expect(fake.store['secure_license'], lic);
    });

    test(
      'retorna vazio (não sobrescreve) quando a leitura falha de forma transitória',
      () async {
        fake.store['secure_license'] = '4321'; // licença real já gravada
        fake.throwOnRead = true;

        final lic = await StorageService.loadOrCreateLicense();

        // Não gera nova nem apaga a existente — preserva a real do dispositivo.
        expect(lic, '');
        expect(fake.store['secure_license'], '4321');
      },
    );
  });

  group('StorageService.saveEtiquetas / loadEtiquetas', () {
    test('filtra produtos inválidos ao salvar', () async {
      await StorageService.saveEtiquetas([
        _produto(), // válido
        _produto(codProduto: ''), // inválido: codProduto vazio
      ]);
      final carregadas = await StorageService.loadEtiquetas();

      expect(carregadas.length, 1);
      expect(carregadas.first.codProduto, '100');
    });

    test('round-trip preserva um produto válido', () async {
      await StorageService.saveEtiquetas([_produto()]);
      final carregadas = await StorageService.loadEtiquetas();
      expect(carregadas.length, 1);
      expect(carregadas.first.produto, 'Arroz');
      expect(carregadas.first.codBarras, '7891234567890');
    });
  });
}
