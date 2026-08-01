import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nymbus_coletor/models/app_config.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/screens/splash_screen.dart';
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

Route<dynamic> _rotas(RouteSettings settings) {
  final marker = switch (settings.name) {
    '/login' => 'LOGIN-ROUTE',
    '/config' => 'CONFIG-ROUTE',
    _ => 'OTHER-ROUTE',
  };
  return MaterialPageRoute<void>(
    builder: (_) => Scaffold(body: Center(child: Text(marker))),
  );
}

Widget _wrap(ConfigProvider provider) {
  return ChangeNotifierProvider<ConfigProvider>.value(
    value: provider,
    child: MaterialApp(home: const SplashScreen(), onGenerateRoute: _rotas),
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

  testWidgets('navega para /config quando não está configurado', (tester) async {
    await tester.pumpWidget(_wrap(ConfigProvider()));

    await tester.pump(); // dispara o addPostFrameCallback
    await tester.pump(const Duration(seconds: 3)); // init + delay de 2s
    await tester.pumpAndSettle();

    expect(find.text('CONFIG-ROUTE'), findsOneWidget);
  });

  testWidgets('navega para /login quando já está configurado', (tester) async {
    await StorageService.saveConfig(
      AppConfig(
        endereco: 'host',
        porta: '1',
        licenca: '1234',
        isConfigured: true,
      ),
    );

    await tester.pumpWidget(_wrap(ConfigProvider()));

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN-ROUTE'), findsOneWidget);
  });
}
