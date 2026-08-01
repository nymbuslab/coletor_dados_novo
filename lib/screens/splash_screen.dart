import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    // Inicializa o provider
    await configProvider.init();

    // Aguarda um pouco para mostrar a splash screen
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navega para a tela apropriada
    if (configProvider.isConfigured) {
      unawaited(navigator.pushReplacementNamed('/login'));
    } else {
      unawaited(navigator.pushReplacementNamed('/config', arguments: 'splash'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Coletor de Dados',
                style: tt.headlineLarge!.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.actionOnDark),
              ),
              const SizedBox(height: 20),
              Text(
                'Inicializando...',
                style: tt.bodyLarge!.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
