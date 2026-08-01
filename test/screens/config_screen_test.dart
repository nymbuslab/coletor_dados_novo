import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/screens/config_screen.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/storage_service.dart';
import 'package:provider/provider.dart';
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

Widget _wrap(ConfigProvider provider) {
  return ChangeNotifierProvider<ConfigProvider>.value(
    value: provider,
    child: const MaterialApp(home: ConfigScreen()),
  );
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

  testWidgets('renderiza o título e o botão de testar conexão', (tester) async {
    await tester.pumpWidget(_wrap(ConfigProvider()));

    expect(find.text('Configurar Servidor'), findsOneWidget);
    expect(find.text('Testar Conexão'), findsOneWidget);
  });

  testWidgets('exibe erros de validação quando os campos estão vazios', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(ConfigProvider()));

    await tester.ensureVisible(find.text('Testar Conexão'));
    await tester.tap(find.text('Testar Conexão'));
    await tester.pump();

    expect(find.text('Por favor, informe o endereço'), findsOneWidget);
    expect(find.text('Por favor, informe a porta'), findsOneWidget);
  });

  testWidgets('botão Salvar começa desabilitado', (tester) async {
    await tester.pumpWidget(_wrap(ConfigProvider()));

    final salvar = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Salvar'),
    );
    expect(salvar.onPressed, isNull);
  });

  testWidgets('testar conexão com sucesso mostra banner de licença válida', (
    tester,
  ) async {
    final provider = ConfigProvider();
    await provider.init(); // gera a licença usada na validação

    await tester.pumpWidget(_wrap(provider));

    await tester.enterText(find.byType(TextFormField).at(0), '10.0.0.1');
    await tester.enterText(find.byType(TextFormField).at(1), '8080');
    await tester.ensureVisible(find.text('Testar Conexão'));
    await tester.tap(find.text('Testar Conexão'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Licença válida'), findsOneWidget);
  });
}
