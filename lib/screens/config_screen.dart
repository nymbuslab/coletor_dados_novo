import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/services/feedback_service.dart';
import 'package:provider/provider.dart';

class ConfigScreen extends StatefulWidget {
  final String? fromScreen;

  const ConfigScreen({super.key, this.fromScreen});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enderecoController = TextEditingController();
  final _portaController = TextEditingController();

  bool _isSyncing = false;
  bool _isConnected = false;
  String? _validationMessage;
  bool _validationSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final config = configProvider.config;
    _enderecoController.text = config.endereco;
    _portaController.text = config.porta;
    _isConnected = configProvider.isConfigured;
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _portaController.dispose();
    super.dispose();
  }

  Future<void> _syncConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSyncing = true;
      _isConnected = false;
      _validationMessage = null;
      _validationSuccess = false;
    });

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);

    try {
      // Salva só para configurar a baseUrl do teste — NÃO marca como configurado
      // ainda; isConfigured só vira true após validar (no botão Salvar).
      final saveSuccess = await configProvider.saveConfig(
        endereco: _enderecoController.text.trim(),
        porta: _portaController.text.trim(),
        markConfigured: false,
      );

      if (!saveSuccess) {
        if (mounted) {
          setState(() {
            _validationMessage = 'Erro ao salvar configuração temporária';
          });
        }
        return;
      }

      final isConnected = await configProvider.testarConectividade();
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _validationMessage =
                'Não foi possível conectar com o servidor. Verifique o endereço e porta.';
            _isConnected = false;
          });
        }
        return;
      }

      final isValid = await configProvider.validarLicenca();

      if (mounted) {
        setState(() {
          _isConnected = isValid;
          _validationSuccess = isValid;
          _validationMessage = isValid
              ? 'Conexão estabelecida com sucesso! Licença válida'
              : 'Conectado, mas licença inválida';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationMessage = 'Erro na sincronização: $e';
          _isConnected = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _saveAndNavigate() async {
    if (!_formKey.currentState!.validate() || !_isConnected) return;

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    final success = await configProvider.saveConfig(
      endereco: _enderecoController.text.trim(),
      porta: _portaController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      FeedbackService.showSnack(
        context,
        'Configuração salva com sucesso!',
        type: FeedbackService.classifyMessage(
          'Configuração salva com sucesso!',
        ),
      );

      if (widget.fromScreen == 'home') {
        // Volta para a Home que já está na pilha em vez de empilhar outra.
        navigator.pop();
      } else {
        unawaited(navigator.pushReplacementNamed('/login'));
      }
    }
  }

  void _voltar() {
    final navigator = Navigator.of(context);
    if (widget.fromScreen == 'home') {
      // Volta para a Home existente (não duplica a tela na pilha).
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: SafeArea(
        child: Consumer<ConfigProvider>(
          builder: (context, configProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.seed.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              size: 48,
                              color: AppColors.seed.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Configurar Servidor', style: tt.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Informe o endereço e porta do servidor',
                            style: tt.bodyMedium!.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Card: Licença ────────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.seed.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.vpn_key_outlined,
                                    size: 18,
                                    color: AppColors.seed,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Licença do dispositivo',
                                  style: tt.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.seed.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.seed.withValues(alpha: 0.20),
                                ),
                              ),
                              child: Text(
                                configProvider.config.licenca.isEmpty
                                    ? 'Aguardando geração...'
                                    : configProvider.config.licenca,
                                style: tt.bodyMedium!.copyWith(
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.5,
                                  color: AppColors.seed,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Card: Conexão ────────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.dns_outlined,
                                    size: 18,
                                    color: AppColors.info,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Dados do servidor', style: tt.titleSmall),
                                const Spacer(),
                                _StatusChip(connected: _isConnected),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _enderecoController,
                              decoration: const InputDecoration(
                                labelText: 'Endereço (IP ou DDNS)',
                                prefixIcon: Icon(Icons.language_outlined),
                                hintText: 'Ex: 192.168.1.100',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, informe o endereço';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _portaController,
                              decoration: const InputDecoration(
                                labelText: 'Porta',
                                prefixIcon: Icon(
                                  Icons.settings_ethernet_outlined,
                                ),
                                hintText: 'Ex: 8787',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, informe a porta';
                                }
                                final port = int.tryParse(value.trim());
                                if (port == null || port < 1 || port > 65535) {
                                  return 'Porta deve ser um número entre 1 e 65535';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Mensagem de validação ────────────────────────────────
                    // Fonte única de mensagem de status da tela (erro ou sucesso).
                    // Não renderizar também configProvider.errorMessage aqui: o
                    // provider seta o mesmo texto e apareceriam dois banners iguais.
                    if (_validationMessage != null) ...[
                      const SizedBox(height: 12),
                      _ValidationBanner(
                        message: _validationMessage!,
                        isSuccess: _validationSuccess,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Botões ───────────────────────────────────────────────
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncConfiguration,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                        _isSyncing ? 'Testando conexão...' : 'Testar Conexão',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.seed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _voltar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Voltar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isConnected ? _saveAndNavigate : null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Salvar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : Colors.grey;
    final label = connected ? 'Conectado' : 'Desconectado';
    final icon = connected ? Icons.wifi : Icons.wifi_off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.success : AppColors.danger;
    final icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
