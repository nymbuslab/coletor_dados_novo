import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/core/widgets/empty_state.dart';
import 'package:nymbus_coletor/core/widgets/status_badge.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/models/produto.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/feedback_service.dart';
import 'package:nymbus_coletor/services/logger_service.dart';
import 'package:nymbus_coletor/services/scanner_service.dart';
import 'package:provider/provider.dart';

class ColetaScreen extends StatefulWidget {
  const ColetaScreen({
    super.key,
    required this.titulo,
    required this.corPrimaria,
    required this.iconeVazio,
    required this.textoListaVazia,
    required this.textoListaVaziaSubtitulo,
    required this.labelBotaoEnvio,
    required this.onCarregarItens,
    required this.onSalvarItens,
    required this.onLimparItens,
    required this.onEnviarItens,
    required this.mensagemItemAdicionado,
    required this.mensagemItemRemovido,
    required this.mensagemEnvioSucesso,
    required this.mensagemListaVazia,
  });

  final String titulo;
  final Color corPrimaria;
  final IconData iconeVazio;
  final String textoListaVazia;
  final String textoListaVaziaSubtitulo;
  final String labelBotaoEnvio;
  final Future<List<InventarioItem>> Function() onCarregarItens;
  final Future<void> Function(List<InventarioItem>) onSalvarItens;
  final Future<void> Function() onLimparItens;
  final Future<void> Function(List<InventarioItem>) onEnviarItens;
  final String mensagemItemAdicionado;
  final String mensagemItemRemovido;
  final String mensagemEnvioSucesso;
  final String mensagemListaVazia;

  @override
  State<ColetaScreen> createState() => _ColetaScreenState();
}

class _ColetaScreenState extends State<ColetaScreen> {
  final _codigoController = TextEditingController();

  bool _isSearching = false;

  final List<InventarioItem> _itens = [];
  int _contadorItens = 1;

  String _formatarQuantidade(double quantidade) {
    if (quantidade == quantidade.toInt()) {
      return quantidade.toInt().toString();
    }
    return quantidade.toString();
  }

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _carregarItens() async {
    try {
      final itensSalvos = await widget.onCarregarItens();
      if (itensSalvos.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _itens.addAll(itensSalvos);
          _contadorItens = _itens.length + 1;
        });
      }
    } catch (e) {
      LoggerService.e('Erro ao carregar itens (${widget.titulo}): $e');
    }
  }

  Future<void> _salvarItens() async {
    try {
      await widget.onSalvarItens(_itens);
    } catch (e) {
      LoggerService.e('Erro ao salvar itens (${widget.titulo}): $e');
    }
  }

  Future<void> _abrirScanner() async {
    try {
      final ctx = context;
      final codigo = await ScannerService.scanBarcode(ctx);
      if (!mounted) return;
      if (codigo != null && codigo.isNotEmpty) {
        _codigoController.text = codigo;
        _pesquisarProduto();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Erro ao abrir scanner: $e');
      }
    }
  }

  Future<void> _pesquisarProduto() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      _showMessage('Digite um código para pesquisar');
      return;
    }

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
        final baseUrl =
            'http://${configProvider.config.endereco}:${configProvider.config.porta}/api';
        ApiService.instance.configure(baseUrl);
      }

      final produto = await ApiService.instance.buscarProdutoFV(codigo);

      if (produto != null) {
        if (!mounted) return;
        _codigoController.clear();
        final novoProduto = Produto.fromJson(produto, _contadorItens);
        _abrirTelaQuantidade(novoProduto);
      } else {
        if (mounted) {
          _showMessage('Produto não encontrado');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Erro ao pesquisar produto: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _abrirTelaQuantidade(Produto produto) async {
    final navigator = Navigator.of(context);
    final resultado = await navigator.pushNamed<InventarioItem>(
      '/inventario-update',
      arguments: produto,
    );

    if (!mounted) return;
    if (resultado != null) {
      setState(() {
        _itens.add(resultado);
        _contadorItens++;
      });
      await _salvarItens();
      _showMessage(widget.mensagemItemAdicionado);
    }
  }

  void _removerItem(int index) async {
    setState(() {
      _itens.removeAt(index);
    });
    await _salvarItens();
    if (!mounted) return;
    _showMessage(widget.mensagemItemRemovido);
  }

  void _editarItem(int index) {
    final item = _itens[index];
    final produto = Produto(
      codProduto: item.codigo.toString(),
      codBarras: item.barras,
      produto: item.produto,
      unidade: item.unidade,
      valorVenda: 0.0,
      dataHoraRequisicao: DateTime.now(),
      numeroItem: item.item,
      dataAtualizacao: '',
      qtdEstoque: item.estoqueAtual,
    );

    _abrirEdicaoItem(produto, index);
  }

  void _abrirEdicaoItem(Produto produto, int index) async {
    final navigator = Navigator.of(context);
    final resultado = await navigator.pushNamed<InventarioItem>(
      '/inventario-update',
      arguments: produto,
    );

    if (!mounted) return;
    if (resultado != null) {
      setState(() {
        _itens[index] = resultado;
      });
      await _salvarItens();
      _showMessage('Item atualizado!');
    }
  }

  Future<void> _enviar() async {
    if (_itens.isEmpty) {
      _showMessage(widget.mensagemListaVazia);
      return;
    }

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    if (!configProvider.isConfigured || configProvider.config.licenca.isEmpty) {
      await FeedbackService.showConfigRequiredDialog(context);
      return;
    }

    final navigator = Navigator.of(context);

    try {
      await widget.onEnviarItens(_itens);
      if (!mounted) return;
      _showMessage(widget.mensagemEnvioSucesso);
      setState(() {
        _itens.clear();
        _contadorItens = 1;
      });

      await widget.onLimparItens();

      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (mounted) {
        _showMessage('Erro ao enviar ${widget.titulo.toLowerCase()}: $e');
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: widget.corPrimaria,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de pesquisa
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Digite o código ou use a câmera para escanear',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextField(
                    controller: _codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código do produto',
                      hintText: 'Digite o código de barras',
                      border: const OutlineInputBorder(),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _abrirScanner,
                        tooltip: 'Escanear código de barras',
                      ),
                    ),
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
                          : const Icon(Icons.search),
                      label: Text(
                        _isSearching ? 'Pesquisando...' : 'Pesquisar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.corPrimaria,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de itens
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _itens.isEmpty
                    ? EmptyState(
                        key: const ValueKey('empty'),
                        icon: widget.iconeVazio,
                        color: widget.corPrimaria,
                        title: widget.textoListaVazia,
                        subtitle: widget.textoListaVaziaSubtitulo,
                      )
                    : ListView.builder(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.all(16),
                        itemCount: _itens.length,
                        itemBuilder: (context, index) =>
                            _buildItemCard(_itens[index], index),
                      ),
              ),
            ),

            const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: _itens.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviar,
                    icon: const Icon(Icons.send),
                    label: Text(
                      '${widget.labelBotaoEnvio} (${_itens.length} itens)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildItemCard(InventarioItem item, int index) {
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: widget.corPrimaria),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          label: 'Item ${item.item.toString().padLeft(3, '0')}',
                          color: widget.corPrimaria,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.barras,
                            style: tt.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.dtCriacaoFormatada,
                          style: tt.labelSmall!.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: Colors.blue,
                          onPressed: () => _editarItem(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red,
                          onPressed: () => _removerItem(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.produto,
                      style: tt.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusBadge(
                          label: 'Atual: ${_formatarQuantidade(item.estoqueAtual)}',
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: 'Novo: ${_formatarQuantidade(item.novoEstoque)}',
                          color: AppColors.success,
                        ),
                        const Spacer(),
                        StatusBadge(label: item.unidade, color: AppColors.info),
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
