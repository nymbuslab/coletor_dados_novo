import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/core/widgets/empty_state.dart';
import 'package:nymbus_coletor/core/widgets/status_badge.dart';
import 'package:nymbus_coletor/models/etiqueta_coletor.dart';
import 'package:nymbus_coletor/models/produto.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/feedback_service.dart';
import 'package:nymbus_coletor/services/logger_service.dart';
import 'package:nymbus_coletor/services/scanner_service.dart';
import 'package:nymbus_coletor/services/storage_service.dart';
import 'package:provider/provider.dart';

class EtiquetaScreen extends StatefulWidget {
  final Produto? produtoParaAdicionar;

  const EtiquetaScreen({super.key, this.produtoParaAdicionar});

  @override
  State<EtiquetaScreen> createState() => _EtiquetaScreenState();
}

class _EtiquetaScreenState extends State<EtiquetaScreen> {
  final _codigoController = TextEditingController();

  bool _isSearching = false;
  bool _isPrinting = false;
  bool _isLoadingEtiquetas = false;

  // Lista de produtos pesquisados
  final List<Produto> _produtosPesquisados = [];
  List<TipoEtiqueta> _tiposEtiquetas = [];
  TipoEtiqueta? _tipoEtiquetaGlobal; // Tipo de etiqueta global
  int _contadorItens = 1;

  @override
  void initState() {
    super.initState();
    // Tipos de etiqueta carregam em paralelo (não interferem na lista salva).
    _carregarTiposEtiquetas();
    // A lista salva precisa terminar de carregar ANTES de adicionar o produto
    // que veio da Consulta de Preço — senão o salvamento do produto novo
    // sobrescreve as etiquetas ainda não carregadas (corrida que apagava a lista).
    _inicializarLista();
  }

  Future<void> _inicializarLista() async {
    await _carregarEtiquetasSalvas();
    if (!mounted) return;
    _adicionarProdutoSeNecessario();
  }

  void _adicionarProdutoSeNecessario() {
    if (widget.produtoParaAdicionar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          final novoProduto = Produto.fromJson(
            widget.produtoParaAdicionar!.toJson(),
            _contadorItens,
          );
          _produtosPesquisados.add(novoProduto);
          _contadorItens++;
        });
        _salvarEtiquetas();
        _showMessage('Produto adicionado à lista de etiquetas!');
      });
    }
  }

  @override
  void dispose() {
    // Salva as etiquetas antes de fechar a tela
    _salvarEtiquetas();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _carregarTiposEtiquetas() async {
    setState(() {
      _isLoadingEtiquetas = true;
    });

    try {
      final configProvider = Provider.of<ConfigProvider>(
        context,
        listen: false,
      );

      // Configura a API se necessário
      if (configProvider.config.endereco.isNotEmpty &&
          configProvider.config.porta.isNotEmpty) {
        final baseUrl =
            'http://${configProvider.config.endereco}:${configProvider.config.porta}/api';
        ApiService.instance.configure(baseUrl);
      }

      final etiquetas = await ApiService.instance.buscarTiposEtiquetas();

      if (mounted) {
        setState(() {
          _tiposEtiquetas = etiquetas
              .map((e) => TipoEtiqueta.fromJson(e))
              .toList();
          if (_tiposEtiquetas.isNotEmpty) {
            // Procura por "Gondola Grande" como padrão
            _tipoEtiquetaGlobal = _tiposEtiquetas.firstWhere(
              (tipo) =>
                  tipo.nome.toLowerCase().contains('gondola') &&
                  tipo.nome.toLowerCase().contains('grande'),
              orElse: () => _tiposEtiquetas.first,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage(FeedbackService.friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEtiquetas = false;
        });
      }
    }
  }

  Future<void> _carregarEtiquetasSalvas() async {
    try {
      final etiquetasSalvas = await StorageService.loadEtiquetas();
      if (!mounted || etiquetasSalvas.isEmpty) return;
      setState(() {
        _produtosPesquisados.addAll(etiquetasSalvas);
        _contadorItens = _produtosPesquisados
                .map((e) => e.numeroItem)
                .reduce((a, b) => a > b ? a : b) +
            1;
      });
    } catch (e) {
      LoggerService.e('Erro ao carregar etiquetas salvas: $e');
    }
  }

  Future<void> _salvarEtiquetas() async {
    try {
      await StorageService.saveEtiquetas(_produtosPesquisados);
    } catch (e) {
      LoggerService.e('Erro ao salvar etiquetas: $e');
    }
  }

  Future<void> _abrirScanner() async {
    try {
      LoggerService.d('EtiquetaScreen: Iniciando scanner...');
      final ctx = context;
      final codigo = await ScannerService.scanBarcode(ctx);
      if (!mounted) return;
      LoggerService.d('EtiquetaScreen: Scanner retornou código: $codigo');

      if (codigo != null && codigo.isNotEmpty) {
        LoggerService.d(
          'EtiquetaScreen: Código válido recebido, definindo no controller...',
        );
        _codigoController.text = codigo;
        LoggerService.d('EtiquetaScreen: Iniciando pesquisa do produto...');
        await _pesquisarProduto();
        LoggerService.d('EtiquetaScreen: Pesquisa do produto concluída');
      } else {
        LoggerService.d(
          'EtiquetaScreen: Código vazio ou nulo recebido do scanner',
        );
      }
    } catch (e) {
      LoggerService.e('EtiquetaScreen: Erro no scanner: $e');
      if (mounted) {
        _showMessage(FeedbackService.friendlyError(e));
      }
    }
  }

  Future<void> _pesquisarProduto() async {
    LoggerService.d('EtiquetaScreen: Iniciando _pesquisarProduto...');
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _showMessage('Digite um código para pesquisar');
      return;
    }

    // Guarda de configuração/licença
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    if (!configProvider.isConfigured || configProvider.config.licenca.isEmpty) {
      await FeedbackService.showConfigRequiredDialog(context);
      return;
    }

    setState(() {
      _isSearching = true;
    });
    try {
      if (configProvider.config.endereco.isNotEmpty &&
          configProvider.config.porta.isNotEmpty) {
        final baseUrl = 'http://${configProvider.config.endereco}:${configProvider.config.porta}/api';
        ApiService.instance.configure(baseUrl);
      }
      final produtoData = await ApiService.instance.buscarProdutoFV(codigo);
      if (produtoData != null) {
        if (!mounted) return;
        final novoProduto = Produto.fromJson(produtoData, _contadorItens);
        if (_tipoEtiquetaGlobal != null) {
          novoProduto.tipoEtiqueta = _tipoEtiquetaGlobal!.nome;
        }
        setState(() {
          _produtosPesquisados.add(novoProduto);
          _contadorItens++;
        });
        await _salvarEtiquetas();
        _codigoController.clear();
        _showMessage('Produto adicionado à lista!');
      } else {
        _showMessage('Produto não encontrado');
      }
    } catch (e) {
      LoggerService.e('EtiquetaScreen: Erro ao pesquisar produto: $e');
      _showMessage(FeedbackService.friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _enviarParaServidor() async {
    LoggerService.d('EtiquetaScreen: Iniciando _enviarParaServidor...');

    if (_produtosPesquisados.isEmpty) {
      _showMessage('Adicione produtos à lista primeiro');
      return;
    }

    if (_tipoEtiquetaGlobal == null) {
      _showMessage('Selecione um tipo de etiqueta');
      return;
    }

    // Guarda de configuração/licença
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    if (!configProvider.isConfigured || configProvider.config.licenca.isEmpty) {
      await FeedbackService.showConfigRequiredDialog(context);
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Configura a API se necessário
      if (configProvider.config.endereco.isNotEmpty &&
          configProvider.config.porta.isNotEmpty) {
        final baseUrl =
            'http://${configProvider.config.endereco}:${configProvider.config.porta}/api';
        ApiService.instance.configure(baseUrl);
      }

      // Converte produtos para o formato da tabela ts_arq_etq
      final etiquetas = _produtosPesquisados.map((produto) {
        return EtiquetaColetor.fromProduto(
          codProduto: produto.codProduto,
          codBarras: produto.codBarras,
          nomeProduto: produto.produto,
          unidade: produto.unidade,
          tipoEtiqueta: _tipoEtiquetaGlobal!.nome,
          preco: produto.valorVenda.toString(),
        );
      }).toList();

      // Envia para a API do coletor
      LoggerService.d(
        'EtiquetaScreen: Enviando ${etiquetas.length} etiqueta(s) para API do coletor...',
      );
      final sucesso = await ApiService.instance.enviarEtiquetasColetor(
        etiquetas,
      );

      if (mounted) {
        if (sucesso) {
          LoggerService.d(
            'EtiquetaScreen: Envio de etiquetas concluído com sucesso',
          );
          _showMessage(
            '${_produtosPesquisados.length} etiqueta(s) enviada(s) para o servidor!',
          );
          _limparLista();
        } else {
          LoggerService.e(
            'EtiquetaScreen: Falha ao enviar etiquetas para o servidor',
          );
          _showMessage('Erro ao enviar etiquetas para o servidor');
        }
      }
    } catch (e) {
      LoggerService.e('EtiquetaScreen: Erro ao enviar etiquetas: $e');
      if (mounted) {
        _showMessage(FeedbackService.friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  void _removerProduto(int index) {
    setState(() {
      _produtosPesquisados.removeAt(index);
    });
    _salvarEtiquetas();
    _showMessage('Produto removido da lista');
  }

  void _limparLista() {
    setState(() {
      _produtosPesquisados.clear();
      _contadorItens = 1;
    });
    // Limpa também as etiquetas salvas
    StorageService.clearEtiquetas();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Etiquetas (${_produtosPesquisados.length})'),
        backgroundColor: AppColors.etiqueta,
        foregroundColor: Colors.white,
        actions: [
          if (_produtosPesquisados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _limparLista,
              tooltip: 'Limpar lista',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Seção de configuração e pesquisa
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Seleção de tipo de etiqueta global
                  if (_isLoadingEtiquetas)
                    const Center(child: CircularProgressIndicator())
                  else if (_tiposEtiquetas.isNotEmpty)
                    DropdownButtonFormField<TipoEtiqueta>(
                      initialValue: _tipoEtiquetaGlobal,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Etiqueta (Global)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _tiposEtiquetas.map((tipo) {
                        return DropdownMenuItem<TipoEtiqueta>(
                          value: tipo,
                          child: Text(
                            tipo.nome,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (TipoEtiqueta? novoTipo) {
                        setState(() {
                          _tipoEtiquetaGlobal = novoTipo;
                        });
                      },
                    ),

                  const SizedBox(height: 16),

                  // Texto de orientação
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: const Text(
                      'Digite o código ou use a câmera para escanear',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Campo de pesquisa
                  TextField(
                    controller: _codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código de Barras',
                      border: const OutlineInputBorder(),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _abrirScanner,
                        tooltip: 'Escanear código de barras',
                      ),
                      hintText: 'Digite ou escaneie o código',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: (_) => _pesquisarProduto(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _pesquisarProduto,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isSearching ? 'Buscando...' : 'Adicionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de produtos
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _produtosPesquisados.isEmpty
                    ? const EmptyState(
                        key: ValueKey('empty'),
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.etiqueta,
                        title: 'Nenhum produto adicionado',
                        subtitle:
                            'Digite um código de barras e clique em "Adicionar"',
                      )
                    : ListView.builder(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.all(16),
                        itemCount: _produtosPesquisados.length,
                        itemBuilder: (context, index) =>
                            _buildProdutoCard(_produtosPesquisados[index], index),
                      ),
              ),
            ),

            // Botão de envio movido para bottomNavigationBar
            const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: _produtosPesquisados.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _enviarParaServidor,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      _isPrinting
                          ? 'Enviando...'
                          : 'Enviar ${_produtosPesquisados.length} Etiqueta(s) para Servidor',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProdutoCard(Produto produto, int index) {
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra lateral colorida
            Container(width: 4, color: AppColors.etiqueta),
            // Conteúdo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: badge + barcode + data + delete
                    Row(
                      children: [
                        StatusBadge(
                          label: produto.numeroItemFormatado,
                          color: AppColors.etiqueta,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            produto.codBarras,
                            style: tt.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          produto.dataHoraFormatada,
                          style: tt.labelSmall!.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red,
                          onPressed: () => _removerProduto(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Linha 2: nome do produto
                    Text(
                      produto.produto,
                      style: tt.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Linha 3: preço + tipo de etiqueta
                    Row(
                      children: [
                        StatusBadge(label: produto.precoFormatado, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatusBadge(
                            label: produto.tipoEtiqueta ?? _tipoEtiquetaGlobal?.nome ?? 'Sem tipo',
                            color: AppColors.warning,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
