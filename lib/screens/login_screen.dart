import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _acessar() async {
    setState(() {
      _isLoading = true;
    });

    final navigator = Navigator.of(context);

    // Simula um delay de carregamento
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      unawaited(navigator.pushReplacementNamed('/home'));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToConfig() {
    final navigator = Navigator.of(context);
    navigator.pushReplacementNamed('/config', arguments: 'login');
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ConfigProvider>(
          builder: (context, configProvider, child) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: AppColors.seed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Coletor de Dados',
                          style: tt.headlineMedium!.copyWith(
                            color: AppColors.seed,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Licença: ${configProvider.config.licenca}',
                          style: tt.bodyMedium!.copyWith(
                            color: Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Verifica se as configurações estão válidas
                        if (!configProvider.config.isConfigured)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Configure o aplicativo antes de acessar',
                                    style: tt.bodyMedium!.copyWith(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!configProvider.config.isConfigured)
                          const SizedBox(height: 24),

                        // Botão Acessar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (configProvider.config.isConfigured &&
                                    !_isLoading)
                                ? _acessar
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.seed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Acessar'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botão Configurações
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _goToConfig,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.seed,
                              side: const BorderSide(color: AppColors.seed),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Configurações'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
