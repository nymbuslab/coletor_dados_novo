import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nymbus_coletor/models/etiqueta_coletor.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/services/logger_service.dart';
import 'package:nymbus_coletor/utils/barcode_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static ApiService get instance => _instance;

  String? _baseUrl;
  bool get isConfigured => _baseUrl != null;

  // Cliente HTTP injetável para facilitar testes
  http.Client _client = http.Client();
  void setClient(http.Client client) {
    _client = client;
  }

  // Timeouts centralizados
  static const Duration _timeoutShort = Duration(seconds: 8);
  static const Duration _timeoutMedium = Duration(seconds: 15);
  static const Duration _timeoutLong = Duration(seconds: 30);

  // Retry/backoff
  static const int _maxRetries = 3;
  static const Duration _baseBackoff = Duration(milliseconds: 600);

  // Handler global para não autorizado (401/403)
  void Function()? _onUnauthorized;
  void setUnauthorizedHandler(void Function() handler) {
    _onUnauthorized = handler;
  }

  // Cache de produtos em memória com TTL
  final Map<String, List<dynamic>> _produtosCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool _cacheValido(String key) {
    final ts = _cacheTimestamp[key];
    if (ts == null) return false;
    return DateTime.now().difference(ts) < _cacheTtl;
  }

  void invalidarCache() {
    _produtosCache.clear();
    _cacheTimestamp.clear();
    LoggerService.d('Cache de produtos invalidado');
  }

  Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };


  void _handleUnauthorized() {
    LoggerService.w(
      'Resposta 401/403 recebida. Disparando redirecionamento para Login.',
    );
    try {
      _onUnauthorized?.call();
    } catch (e, st) {
      LoggerService.e('Erro ao executar handler de não autorizado', e, st);
    }
  }

  bool _shouldRetryError(Object e) {
    final s = e.toString();
    return e is TimeoutException ||
        e is http.ClientException ||
        // FormatException cobre falhas de descompressão gzip em respostas grandes
        (e is FormatException && s.contains('bad data')) ||
        s.contains('Failed host lookup') ||
        s.contains('Network') ||
        s.contains('SocketException') ||
        s.contains('Failed to fetch');
  }

  Duration _backoffDelay(int attempt) {
    final ms = _baseBackoff.inMilliseconds * (1 << (attempt - 1));
    return Duration(milliseconds: ms);
  }


  Future<http.Response> _get(
    Uri url, {
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await _client
            .get(url, headers: headers)
            .timeout(timeout ?? _timeoutMedium);
        if (response.statusCode == 401 || response.statusCode == 403) {
          _handleUnauthorized();
        }
        return response;
      } catch (e) {
        attempt++;
        if (attempt > _maxRetries || !_shouldRetryError(e)) {
          rethrow;
        }
        final delay = _backoffDelay(attempt);
        LoggerService.w(
          'Falha na requisição GET (tentativa $attempt). Retentando em ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      }
    }
  }

  Future<http.Response> _post(
    Uri url, {
    Duration? timeout,
    Map<String, String>? headers,
    Object? body,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await _client
            .post(url, headers: headers, body: body)
            .timeout(timeout ?? _timeoutMedium);
        if (response.statusCode == 401 || response.statusCode == 403) {
          _handleUnauthorized();
        }
        return response;
      } catch (e) {
        attempt++;
        if (attempt > _maxRetries || !_shouldRetryError(e)) {
          rethrow;
        }
        final delay = _backoffDelay(attempt);
        LoggerService.w(
          'Falha na requisição POST (tentativa $attempt). Retentando em ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      }
    }
  }

  /// Configura a URL base da API
  void configure(String baseUrl) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    // Permite HTTP em release conforme necessidade do usuário
    // if (kReleaseMode && normalized.startsWith('http://')) {
    //   throw Exception('Em produção, a URL base deve usar HTTPS');
    // }
    // Troca real de servidor invalida o cache em memória — evita devolver
    // produto do servidor anterior dentro do TTL. Mesma URL não invalida
    // (as telas chamam configure a cada busca), preservando o cache normal.
    if (_baseUrl != null && _baseUrl != normalized) {
      invalidarCache();
    }
    _baseUrl = normalized;
  }

  /// Testa a conectividade com a API
  Future<bool> testarConectividade([String? licenca]) async {
    if (!isConfigured) return false;
    try {
      final licencaTeste = licenca ?? '0000';
      // Codifica só o segmento da licença (byte-idêntico p/ dígitos; blinda
      // contra caractere especial). Não altera a URL das licenças reais.
      final url = Uri.parse('$_baseUrl/licenca/${Uri.encodeComponent(licencaTeste)}');
      LoggerService.d('Testando conectividade com: $url');
      final response = await _get(url, timeout: _timeoutShort);
      LoggerService.d(
        'Resposta recebida - Status: ${response.statusCode}, Body length: ${response.body.length}',
      );
      return response.statusCode < 500;
    } catch (e) {
      LoggerService.e('Erro de conectividade detalhado: $e');
      LoggerService.d('Tipo do erro: ${e.runtimeType}');
      if (e.toString().contains('Failed to fetch')) {
        LoggerService.w(
          'POSSÍVEL ERRO DE CORS: O navegador está bloqueando a requisição',
        );
        LoggerService.w(
          'Verifique se o servidor da API tem CORS configurado para: ${Uri.base.origin}',
        );
      }
      return false;
    }
  }

  /// Valida uma licença através da API
  Future<bool> validarLicenca(String licenca) async {
    if (!isConfigured) {
      throw Exception('API não configurada');
    }
    try {
      final url = Uri.parse('$_baseUrl/licenca/${Uri.encodeComponent(licenca)}');
      LoggerService.d('Validando licença com: $url');
      final response = await _get(url, timeout: _timeoutMedium);
      LoggerService.d('Validação - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseBody = response.body.toLowerCase().trim();
        final isValid = responseBody == 'ok';
        LoggerService.i('Licença ${isValid ? 'VÁLIDA' : 'INVÁLIDA'}');
        return isValid;
      } else if (response.statusCode == 404) {
        LoggerService.i('Licença não encontrada (404)');
        return false;
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          _handleUnauthorized();
        }
        LoggerService.e('Erro do servidor: ${response.statusCode}');
        throw Exception('Erro do servidor: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('Erro detalhado na validação: $e');
      LoggerService.d('Tipo do erro: ${e.runtimeType}');
      if (e.toString().contains('Failed to fetch')) {
        LoggerService.w(
          'ERRO DE CORS: Configure o servidor para aceitar requisições de: ${Uri.base.origin}',
        );
      }
      throw Exception('Erro ao validar licença: $e');
    }
  }

  /// Método simplificado para validação de licença
  Future<bool> validarLicencaSimples(String licenca) async {
    try {
      return await validarLicenca(licenca);
    } catch (e) {
      LoggerService.e('Erro na validação: $e');
      return false;
    }
  }

  /// Busca um produto pelo cod_barras dentro de uma lista JSON já decodificada
  Map<String, dynamic>? _buscarNaLista(List<dynamic> data, String codigoBarras) {
    int itemsProcessados = 0;
    for (var item in data) {
      itemsProcessados++;
      if (item == null || item is! Map<String, dynamic>) continue;
      try {
        final codBarras = item['cod_barras'];
        if (codBarras == null) continue;
        if (BarcodeUtils.normalizeForCompare(codBarras.toString()) ==
            BarcodeUtils.normalizeForCompare(codigoBarras)) {
          LoggerService.d('PRODUTO ENCONTRADO no item $itemsProcessados!');
          return item;
        }
      } catch (_) {
        continue;
      }
      if (itemsProcessados % 1000 == 0) {
        LoggerService.d('Processados $itemsProcessados itens...');
      }
    }
    LoggerService.d('Busca concluída. Items processados: $itemsProcessados');
    return null;
  }

  /// Busca um produto pelo barcode usando o endpoint individual (?barcode=)
  /// Retorna o produto com todos os campos, incluindo valor_compra.
  Future<Map<String, dynamic>?> buscarProdutoPorBarcode(String codigoBarras) async {
    if (!isConfigured) throw Exception('API não configurada');
    try {
      final codigoSan = BarcodeUtils.sanitize(codigoBarras);
      final url = Uri.parse('$_baseUrl/produtos').replace(
        queryParameters: {'barcode': codigoSan},
      );
      LoggerService.d('Buscando produto por barcode: ${LoggerService.redactUrl(url.toString())}');
      final response = await _get(url, timeout: _timeoutMedium);
      LoggerService.d('Busca por barcode - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        if (data is List) {
          // O servidor pode ignorar o filtro ?barcode= e devolver a lista
          // inteira. Filtramos pelo cod_barras para não retornar o primeiro
          // item da lista (produto errado). Retorna null se não encontrar.
          return _buscarNaLista(data, codigoBarras);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro do servidor: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('Erro na busca por barcode: $e');
      throw Exception('Erro ao buscar produto: $e');
    }
  }

  /// Busca tipos de etiquetas disponíveis
  Future<List<Map<String, dynamic>>> buscarTiposEtiquetas() async {
    if (!isConfigured) {
      throw Exception('API não configurada');
    }
    try {
      final url = Uri.parse('$_baseUrl/etiquetas');
      LoggerService.d('Buscando tipos de etiquetas com: ${LoggerService.redactUrl(url.toString())}');
      final response = await _get(url, timeout: _timeoutMedium);
      LoggerService.d('Busca etiquetas - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          return [data as Map<String, dynamic>];
        }
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          _handleUnauthorized();
        }
        LoggerService.e('Erro do servidor: ${response.statusCode}');
        throw Exception('Erro do servidor: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('Erro detalhado na busca de etiquetas: $e');
      throw Exception('Erro ao buscar tipos de etiquetas: $e');
    }
  }

  /// Envia dados coletados para a API
  Future<bool> enviarDados(Map<String, dynamic> dados) async {
    if (!isConfigured) {
      throw Exception('API não configurada');
    }
    try {
      final url = Uri.parse('$_baseUrl/dados');
      final response = await _post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode(dados),
        timeout: _timeoutLong,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      throw Exception('Erro ao enviar dados: $e');
    }
  }

  /// Envia etiquetas para o coletor (tabela ts_arq_etq)
  Future<bool> enviarEtiquetasColetor(List<EtiquetaColetor> etiquetas) async {
    if (!isConfigured) {
      throw Exception('API não configurada');
    }
    try {
      final itens = etiquetas
          .map(
            (etiqueta) => {
              'codigo': int.tryParse(etiqueta.etqCodmat ?? '0') ?? 0,
              'barras': BarcodeUtils.sanitize(etiqueta.etqEan13 ?? ''),
              'produto': etiqueta.etqDesc ?? '',
              'un': etiqueta.etqUn ?? '',
              'qtd': etiqueta.etqQtd ?? 1,
              'dt_criacao': etiqueta.etqDthora ?? DateTime.now().toString(),
              'danfe_etq': etiqueta.layetqText ?? '',
            },
          )
          .toList();

      final requestBody = {'coleta': 'ETIQUETA', 'imei': 7829, 'itens': itens};
      final url = Uri.parse('$_baseUrl/coletor');
      final response = await _post(
        url,
        headers: {
          ..._jsonHeaders,
          'User-Agent': 'Mozilla/3.0 (compatible; IndyLibrary)',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(requestBody),
        timeout: _timeoutLong,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao enviar etiquetas para o coletor: $e');
    }
  }

  /// Busca dados do produto por código de barras usando a API /api/fv/produtos
  Future<Map<String, dynamic>?> buscarProdutoFV(String codigoBarras) async {
    if (!isConfigured) throw Exception('API não configurada');
    try {
      const cacheKey = 'fv_produtos';
      LoggerService.d('Código de barras procurado: "${LoggerService.maskBarcode(BarcodeUtils.sanitize(codigoBarras))}"');

      if (_cacheValido(cacheKey)) {
        LoggerService.d('Cache hit /fv/produtos (${_produtosCache[cacheKey]!.length} itens)');
        return _buscarNaLista(_produtosCache[cacheKey]!, codigoBarras);
      }

      final url = Uri.parse('$_baseUrl/fv/produtos');
      LoggerService.d('Buscando produto FV com: ${LoggerService.redactUrl(url.toString())}');
      final response = await _get(url, timeout: _timeoutLong);
      LoggerService.d('Busca FV - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        LoggerService.d('Tamanho da resposta: ${response.body.length} caracteres');
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            LoggerService.d('Total de produtos recebidos: ${data.length}');
            _produtosCache[cacheKey] = data;
            _cacheTimestamp[cacheKey] = DateTime.now();
            final produto = _buscarNaLista(data, codigoBarras);
            if (produto != null) {
              LoggerService.i('Produto encontrado com sucesso!');
              return produto;
            }
            LoggerService.i('Produto não encontrado na lista de ${data.length} itens');
            return null;
          } else if (data is Map<String, dynamic>) {
            return data;
          } else {
            return null;
          }
        } catch (e) {
          LoggerService.e('Erro ao decodificar JSON: $e');
          throw Exception('Erro ao processar resposta da API: $e');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('Erro na busca do produto FV: $e');
      throw Exception('Erro ao buscar produto: $e');
    }
  }

  Future<void> enviarInventario(List<InventarioItem> itens) async {
    if (_baseUrl?.isEmpty ?? true) {
      throw Exception('URL base não configurada');
    }
    try {
      LoggerService.d('Enviando inventário com ${itens.length} itens...');
      final inventarioRequest = InventarioRequest(itens: itens);
      final url = Uri.parse('$_baseUrl/coletor');
      LoggerService.d('URL do inventário: ${LoggerService.redactUrl(url.toString())}');
      final body = jsonEncode(inventarioRequest.toJson()); // Conteúdo sensível não será logado
      // Evita logar corpo completo
      LoggerService.d('Tamanho do corpo da requisição: ${body.length}');
      final response = await _post(
        url,
        headers: _jsonHeaders,
        body: body,
        timeout: _timeoutLong,
      );
      LoggerService.d('Status da resposta: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        LoggerService.i('Inventário enviado com sucesso!');
      } else {
        LoggerService.e('Erro HTTP: ${response.statusCode}');
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('Erro ao enviar inventário: $e');
      throw Exception('Erro ao enviar inventário: $e');
    }
  }

  Future<void> enviarEntrada(List<InventarioItem> itens) async {
    if (_baseUrl?.isEmpty ?? true) {
      throw Exception('URL base não configurada');
    }
    try {
      LoggerService.d('Enviando entrada com ${itens.length} itens...');
      final entradaRequest = InventarioRequest(coleta: 'ENTRADA', itens: itens);
      final url = Uri.parse('$_baseUrl/coletor');
      LoggerService.d('URL da entrada: $url');
      final body = jsonEncode(entradaRequest.toJson());
      // Evita logar corpo completo
      LoggerService.d('Tamanho do corpo da requisição: ${body.length}');
      final response = await _post(
        url,
        headers: _jsonHeaders,
        body: body,
        timeout: _timeoutLong,
      );
      LoggerService.d('Status da resposta: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        LoggerService.i('Entrada enviada com sucesso!');
      } else {
        LoggerService.e('Erro HTTP: ${response.statusCode}');
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('Erro ao enviar entrada: $e');
      throw Exception('Erro ao enviar entrada: $e');
    }
  }
}
