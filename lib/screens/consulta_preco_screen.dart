import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/core/widgets/empty_state.dart';
import 'package:nymbus_coletor/models/produto.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/feedback_service.dart';
import 'package:nymbus_coletor/services/scanner_service.dart';
import 'package:provider/provider.dart';

class ConsultaPrecoScreen extends StatefulWidget {
  const ConsultaPrecoScreen({super.key});

  @override
  State<ConsultaPrecoScreen> createState() => _ConsultaPrecoScreenState();
}

class _ConsultaPrecoScreenState extends State<ConsultaPrecoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  bool _isSearching = false;
  Produto? _produtoEncontrado;

  // Sequência da consulta: cada consulta captura seu número e só aplica o
  // resultado (inclusive o assíncrono atrasado do valor de compra) se ainda for
  // a consulta mais recente — evita que a resposta de um código antigo
  // sobrescreva o produto de um código consultado depois.
  int _consultaSeq = 0;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _abrirScanner() async {
    try {
      final ctx = context;
      final codigo = await ScannerService.scanBarcode(ctx);
      if (!mounted) return;
      if (codigo != null && codigo.isNotEmpty) {
        _codigoController.text = codigo;
        await _consultarProduto();
      }
    } catch (e) {
      if (mounted) {
        _showMessage(FeedbackService.friendlyError(e));
      }
    }
  }

  Future<void> _consultarProduto() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _showMessage('Digite um código para consultar');
      return;
    }

    // Guarda de configuração/licença
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    if (!configProvider.isConfigured || configProvider.config.licenca.isEmpty) {
      await FeedbackService.showConfigRequiredDialog(context);
      return;
    }

    final int seq = ++_consultaSeq;

    setState(() {
      _isSearching = true;
    });
    try {
      final produtoFVData = await ApiService.instance.buscarProdutoFV(codigo);
      // Ignora se a tela sumiu ou se já houve uma consulta mais recente.
      if (!mounted || seq != _consultaSeq) return;
      if (produtoFVData != null) {
        setState(() {
          _produtoEncontrado = Produto.fromJson(produtoFVData, 0);
        });
        // Busca valor_compra via endpoint individual (?barcode=) se o FV não trouxe.
        if (produtoFVData['valor_compra'] == null) {
          unawaited(
            ApiService.instance
                .buscarProdutoPorBarcode(codigo)
                .then((produtoData) {
                  // Descarta resposta atrasada se já houve outra consulta.
                  if (!mounted || seq != _consultaSeq) return;
                  if (produtoData != null &&
                      produtoData['valor_compra'] != null) {
                    setState(() {
                      _produtoEncontrado = Produto.fromJson({
                        ...produtoFVData,
                        'valor_compra': produtoData['valor_compra'],
                      }, 0);
                    });
                  }
                })
                .catchError((_) {}),
          );
        }
      } else {
        _showMessage('Produto não encontrado');
      }
    } catch (e) {
      if (mounted && seq == _consultaSeq) {
        _showMessage(FeedbackService.friendlyError(e));
      }
    } finally {
      // Só a consulta mais recente controla o indicador de carregamento.
      if (mounted && seq == _consultaSeq) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _enviarParaEtiqueta() {
    if (_produtoEncontrado != null) {
      final navigator = Navigator.of(context);
      navigator.pushNamed('/etiqueta', arguments: _produtoEncontrado);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    FeedbackService.showSnack(
      context,
      message,
      type: FeedbackService.classifyMessage(message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de Preço'),
        backgroundColor: AppColors.consulta,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo de pesquisa
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Texto de orientação
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Digite o código ou use a câmera para escanear',
                          style: tt.bodyMedium!.copyWith(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextField(
                        controller: _codigoController,
                        decoration: InputDecoration(
                          labelText: 'Código do Produto',
                          hintText: 'Digite o código ou código de barras',
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _abrirScanner,
                            tooltip: 'Escanear código de barras',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _consultarProduto(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSearching ? null : _consultarProduto,
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(
                            _isSearching ? 'Consultando...' : 'Consultar',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.consulta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Resultado da consulta
              if (_produtoEncontrado != null) ...[
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações do Produto',
                            style: tt.titleLarge!.copyWith(
                              color: AppColors.consulta,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'Código do Produto',
                                    _produtoEncontrado!.codProduto,
                                  ),
                                  _buildInfoRow(
                                    'Código de Barras',
                                    _produtoEncontrado!.codBarras,
                                  ),
                                  _buildInfoRow(
                                    'Produto',
                                    _produtoEncontrado!.produto,
                                  ),
                                  _buildInfoRow(
                                    'Unidade',
                                    _produtoEncontrado!.unidade,
                                  ),
                                  _buildInfoRow(
                                    'Valor de Venda',
                                    _produtoEncontrado!.precoFormatado,
                                  ),
                                  _buildInfoRow(
                                    'Valor Ult. Compra',
                                    _produtoEncontrado!.valorCompraFormatado,
                                  ),
                                  _buildInfoRow(
                                    'Qtd. Estoque',
                                    _produtoEncontrado!.qtdEstoqueFormatada,
                                  ),
                                  _buildInfoRow(
                                    'Data Atualização',
                                    _produtoEncontrado!
                                        .dataAtualizacaoFormatada,
                                  ),
                                  _buildInfoRow(
                                    'Data/Hora Consulta',
                                    _produtoEncontrado!.dataHoraFormatada,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Botão enviar para etiqueta movido para bottomNavigationBar
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (!_isSearching) ...[
                const Expanded(
                  child: EmptyState(
                    icon: Icons.search,
                    color: AppColors.consulta,
                    title: 'Nenhum produto consultado',
                    subtitle:
                        'Digite um código ou escaneie para consultar o preço',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _produtoEncontrado != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviarParaEtiqueta,
                    icon: const Icon(Icons.label),
                    label: const Text('Enviar para Etiqueta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: tt.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium!.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
