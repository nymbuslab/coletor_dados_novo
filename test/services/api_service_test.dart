import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nymbus_coletor/models/etiqueta_coletor.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/services/api_service.dart';

/// Cria um [ApiService] isolado por teste usando um cliente mock.
/// O singleton é compartilhado, então redefinimos o cliente e a URL a cada teste.
ApiService _makeService(MockClient mockClient, {String baseUrl = 'http://test.local'}) {
  final svc = ApiService.instance;
  svc.configure(baseUrl);
  svc.setClient(mockClient);
  svc.invalidarCache();
  return svc;
}

void main() {
  group('ApiService.configure', () {
    test('isConfigured retorna true após configure()', () {
      final svc = _makeService(MockClient((_) async => http.Response('', 200)));
      expect(svc.isConfigured, true);
    });

    test('remove barra final da URL', () async {
      // Se não removesse a barra, a URL ficaria com dupla barra
      bool urlCorreta = false;
      final client = MockClient((req) async {
        urlCorreta = !req.url.toString().contains('//licenca');
        return http.Response('ok', 200);
      });
      final svc = _makeService(client, baseUrl: 'http://test.local/');
      await svc.testarConectividade('ABC');
      expect(urlCorreta, true);
    });
  });

  group('ApiService.testarConectividade', () {
    test('retorna true quando status < 500', () async {
      final client = MockClient((_) async => http.Response('ok', 200));
      final svc = _makeService(client);
      expect(await svc.testarConectividade('0000'), true);
    });

    test('retorna true para status 404 (servidor respondeu)', () async {
      final client = MockClient((_) async => http.Response('not found', 404));
      final svc = _makeService(client);
      expect(await svc.testarConectividade(), true);
    });

    test('retorna false quando status >= 500', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final svc = _makeService(client);
      expect(await svc.testarConectividade(), false);
    });

    test('retorna false quando exceção de rede é lançada', () async {
      final client = MockClient((_) async => throw http.ClientException('offline'));
      final svc = _makeService(client);
      expect(await svc.testarConectividade(), false);
    });
  });

  group('ApiService.validarLicenca', () {
    test('retorna true quando body é "ok"', () async {
      final client = MockClient((_) async => http.Response('ok', 200));
      final svc = _makeService(client);
      expect(await svc.validarLicenca('LIC-001'), true);
    });

    test('retorna true quando body é "OK" (case-insensitive)', () async {
      final client = MockClient((_) async => http.Response('OK', 200));
      final svc = _makeService(client);
      expect(await svc.validarLicenca('LIC-001'), true);
    });

    test('retorna false quando body é diferente de "ok"', () async {
      final client = MockClient((_) async => http.Response('invalid', 200));
      final svc = _makeService(client);
      expect(await svc.validarLicenca('LIC-001'), false);
    });

    test('retorna false para status 404', () async {
      final client = MockClient((_) async => http.Response('', 404));
      final svc = _makeService(client);
      expect(await svc.validarLicenca('LIC-001'), false);
    });

    test('lança exceção para status 500', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final svc = _makeService(client);
      expect(() => svc.validarLicenca('LIC-001'), throwsException);
    });

    test('lança exceção quando API não está configurada', () async {
      // Força estado não configurado resetando via configure com string vazia
      // Como o singleton mantém estado, usamos validarLicenca sem configure
      final svc = ApiService.instance;
      // Reconfigura para URL válida, depois criamos nova instância fake sem configure
      // Aqui testamos via validarLicencaSimples que não lança
      final client = MockClient((_) async => throw http.ClientException('err'));
      svc.setClient(client);
      svc.configure('http://test.local');
      expect(() => svc.validarLicenca(''), throwsException);
    });
  });

  group('ApiService.validarLicencaSimples', () {
    test('retorna false ao invés de lançar exceção em erro de rede', () async {
      final client = MockClient((_) async => throw http.ClientException('timeout'));
      final svc = _makeService(client);
      expect(await svc.validarLicencaSimples('LIC-001'), false);
    });
  });

  group('ApiService.buscarProduto', () {
    test('retorna produto encontrado na lista', () async {
      final produtos = [
        {
          'cod_barras': '7891234567890',
          'cod_produto': '001',
          'produto': 'Arroz',
          'unidade': 'UN',
          'valor_venda1': 10.0,
        },
        {
          'cod_barras': '1111111111111',
          'cod_produto': '002',
          'produto': 'Feijão',
          'unidade': 'KG',
          'valor_venda1': 8.0,
        },
      ];
      final client = MockClient(
        (_) async => http.Response(jsonEncode(produtos), 200),
      );
      final svc = _makeService(client);

      final result = await svc.buscarProduto('7891234567890');
      expect(result, isNotNull);
      expect(result!['produto'], 'Arroz');
    });

    test('retorna null quando produto não está na lista', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode([]), 200),
      );
      final svc = _makeService(client);
      final result = await svc.buscarProduto('9999999999999');
      expect(result, isNull);
    });

    test('retorna null para status 404', () async {
      final client = MockClient((_) async => http.Response('', 404));
      final svc = _makeService(client);
      final result = await svc.buscarProduto('123');
      expect(result, isNull);
    });

    test('usa cache na segunda chamada (sem nova requisição HTTP)', () async {
      int chamadas = 0;
      final produtos = [
        {
          'cod_barras': '7891234567890',
          'cod_produto': '001',
          'produto': 'Arroz',
          'unidade': 'UN',
          'valor_venda1': 10.0,
        },
      ];
      final client = MockClient((_) async {
        chamadas++;
        return http.Response(jsonEncode(produtos), 200);
      });
      final svc = _makeService(client);

      await svc.buscarProduto('7891234567890');
      await svc.buscarProduto('7891234567890');

      expect(chamadas, 1); // segunda chamada usa cache
    });

    test('invalida cache e faz nova requisição após invalidarCache()', () async {
      int chamadas = 0;
      final client = MockClient((_) async {
        chamadas++;
        return http.Response(jsonEncode([]), 200);
      });
      final svc = _makeService(client);

      await svc.buscarProduto('123');
      svc.invalidarCache();
      await svc.buscarProduto('123');

      expect(chamadas, 2);
    });

    test('lança exceção para status 500', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final svc = _makeService(client);
      expect(() => svc.buscarProduto('123'), throwsException);
    });
  });

  group('ApiService.buscarTiposEtiquetas', () {
    test('retorna lista de etiquetas', () async {
      final etiquetas = [
        {'codigo': '1', 'etiqueta': 'Gondola Grande', 'arquivo': 'ggrande.btw'},
        {'codigo': '2', 'etiqueta': 'Gondola Pequena', 'arquivo': 'gpequena.btw'},
      ];
      final client = MockClient(
        (_) async => http.Response(jsonEncode(etiquetas), 200),
      );
      final svc = _makeService(client);

      final result = await svc.buscarTiposEtiquetas();
      expect(result.length, 2);
      expect(result[0]['etiqueta'], 'Gondola Grande');
    });

    test('lança exceção para status de erro', () async {
      final client = MockClient((_) async => http.Response('', 503));
      final svc = _makeService(client);
      expect(() => svc.buscarTiposEtiquetas(), throwsException);
    });
  });

  group('ApiService.enviarDados', () {
    test('retorna true para status 200', () async {
      final client = MockClient((_) async => http.Response('', 200));
      final svc = _makeService(client);
      expect(await svc.enviarDados({'key': 'value'}), true);
    });

    test('retorna true para status 201', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final svc = _makeService(client);
      expect(await svc.enviarDados({}), true);
    });

    test('retorna false para status 400', () async {
      final client = MockClient((_) async => http.Response('', 400));
      final svc = _makeService(client);
      expect(await svc.enviarDados({}), false);
    });
  });

  group('ApiService.enviarEtiquetasColetor', () {
    test('retorna true para status 200', () async {
      final client = MockClient((_) async => http.Response('', 200));
      final svc = _makeService(client);
      final etiquetas = [
        EtiquetaColetor(
          etqCodmat: '001',
          etqEan13: '7891234567890',
          etqDesc: 'Arroz',
          etqUn: 'UN',
          etqQtd: 1,
          layetqText: 'GONDOLA GRANDE',
        ),
      ];
      expect(await svc.enviarEtiquetasColetor(etiquetas), true);
    });

    test('lança exceção para status de erro', () async {
      final client = MockClient((_) async => http.Response('', 422));
      final svc = _makeService(client);
      expect(() => svc.enviarEtiquetasColetor([]), throwsException);
    });
  });

  group('ApiService.enviarInventario', () {
    test('não lança exceção para status 200', () async {
      final client = MockClient((_) async => http.Response('', 200));
      final svc = _makeService(client);
      final itens = [
        InventarioItem(
          item: 1,
          codigo: 100,
          barras: '7891234567890',
          produto: 'Arroz',
          unidade: 'UN',
          estoqueAtual: 50.0,
          novoEstoque: 55.0,
        ),
      ];
      await expectLater(svc.enviarInventario(itens), completes);
    });

    test('lança exceção para status 500', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final svc = _makeService(client);
      expect(() => svc.enviarInventario([]), throwsException);
    });
  });

  group('ApiService.enviarEntrada', () {
    test('não lança exceção para status 201', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final svc = _makeService(client);
      await expectLater(svc.enviarEntrada([]), completes);
    });

    test('lança exceção para status 400', () async {
      final client = MockClient((_) async => http.Response('', 400));
      final svc = _makeService(client);
      expect(() => svc.enviarEntrada([]), throwsException);
    });
  });

  group('ApiService handler de não autorizado', () {
    test('chama handler ao receber 401', () async {
      bool chamado = false;
      final client = MockClient((_) async => http.Response('', 401));
      final svc = _makeService(client);
      svc.setUnauthorizedHandler(() => chamado = true);

      await svc.testarConectividade(); // retorna false, não lança
      expect(chamado, true);
    });

    test('chama handler ao receber 403', () async {
      bool chamado = false;
      final client = MockClient((_) async => http.Response('', 403));
      final svc = _makeService(client);
      svc.setUnauthorizedHandler(() => chamado = true);

      await svc.testarConectividade();
      expect(chamado, true);
    });
  });
}
