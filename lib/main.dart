import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/models/produto.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/screens/config_screen.dart';
import 'package:nymbus_coletor/screens/consulta_preco_screen.dart';
import 'package:nymbus_coletor/screens/etiqueta_screen.dart';
import 'package:nymbus_coletor/screens/home_screen.dart';
import 'package:nymbus_coletor/screens/inventario_screen.dart';
import 'package:nymbus_coletor/screens/inventario_update_screen.dart';
import 'package:nymbus_coletor/screens/login_screen.dart';
import 'package:nymbus_coletor/screens/splash_screen.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/logger_service.dart';
import 'package:nymbus_coletor/services/scanner_service.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Captura global de erros: tudo que escapar do framework ou de um Future
  // vai para o log (que já mascara dados sensíveis), em vez de sumir ou só
  // pintar a tela vermelha sem registro.
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        LoggerService.e(
          'Erro não tratado do Flutter',
          details.exception,
          details.stack,
        );
        // Mantém o comportamento padrão em debug (tela vermelha/console).
        if (!kReleaseMode) {
          FlutterError.presentError(details);
        }
      };

      // Registra o handler global de não autorizado (401/403) uma única vez,
      // fora do build() — antes ele era re-registrado a cada rebuild do MyApp.
      ApiService.instance.setUnauthorizedHandler(() {
        final nav = _rootNavigatorKey.currentState;
        if (nav == null) return;
        nav.pushNamedAndRemoveUntil('/login', (route) => false);
      });

      runApp(const MyApp());
    },
    (error, stack) {
      LoggerService.e('Erro não tratado (zona)', error, stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ConfigProvider(),
      child: MaterialApp(
        navigatorKey: _rootNavigatorKey,
        title: 'Coletor de Dados',
        theme: AppTheme.light(),
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/config':
              final from = (settings.arguments as String?) ?? 'login';
              return MaterialPageRoute(
                builder: (_) => ConfigScreen(fromScreen: from),
              );
            case '/etiqueta':
              final produtoArg = settings.arguments as Produto?;
              return MaterialPageRoute(
                builder: (_) =>
                    EtiquetaScreen(produtoParaAdicionar: produtoArg),
              );
            case '/consulta':
              return MaterialPageRoute(
                builder: (_) => const ConsultaPrecoScreen(),
              );
            case '/inventario':
              return MaterialPageRoute(
                builder: (_) => const InventarioScreen(),
              );
            case '/scanner':
              return MaterialPageRoute<String>(
                builder: (_) => const BarcodeScannerScreen(),
              );
            case '/inventario-update':
              // Cast defensivo: sem produto no argumento, volta ao Splash em
              // vez de estourar (rota exige um Produto para funcionar).
              final produto = settings.arguments as Produto?;
              if (produto == null) {
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              }
              return MaterialPageRoute<InventarioItem>(
                builder: (_) => InventarioUpdateScreen(produto: produto),
              );
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
