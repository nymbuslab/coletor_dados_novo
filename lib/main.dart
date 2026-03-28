import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/models/produto.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/screens/config_screen.dart';
import 'package:nymbus_coletor/screens/consulta_preco_screen.dart';
import 'package:nymbus_coletor/screens/entrada_screen.dart';
import 'package:nymbus_coletor/screens/etiqueta_screen.dart';
import 'package:nymbus_coletor/screens/home_screen.dart';
import 'package:nymbus_coletor/screens/inventario_screen.dart';
import 'package:nymbus_coletor/screens/inventario_update_screen.dart';
import 'package:nymbus_coletor/screens/login_screen.dart';
import 'package:nymbus_coletor/screens/splash_screen.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/scanner_service.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Registra handler global de nÃ£o autorizado (401/403) para redirecionar ao Login
    ApiService.instance.setUnauthorizedHandler(() {
      final nav = _rootNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    });

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
            case '/entrada':
              return MaterialPageRoute(builder: (_) => const EntradaScreen());
            case '/scanner':
              return MaterialPageRoute<String>(
                builder: (_) => const BarcodeScannerScreen(),
              );
            case '/inventario-update':
              final produto = settings.arguments as Produto;
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
