import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';

void main() {
  final dtFixa = DateTime(2025, 6, 15, 14, 30, 0);

  InventarioItem makeItem({
    int item = 1,
    int codigo = 100,
    String barras = '7891234567890',
    String produto = 'Arroz Tipo 1',
    String unidade = 'UN',
    double estoqueAtual = 50.0,
    double novoEstoque = 60.0,
    DateTime? dtCriacao,
  }) {
    return InventarioItem(
      item: item,
      codigo: codigo,
      barras: barras,
      produto: produto,
      unidade: unidade,
      estoqueAtual: estoqueAtual,
      novoEstoque: novoEstoque,
      dtCriacao: dtCriacao ?? dtFixa,
    );
  }

  group('InventarioItem.toJson', () {
    test('serializa campos corretamente', () {
      final item = makeItem();
      final json = item.toJson();

      expect(json['codigo'], 100);
      expect(json['barras'], '7891234567890');
      expect(json['produto'], 'Arroz Tipo 1');
      expect(json['un'], 'UN');
      expect(json['qtd'], 60.0);
      expect(json['danfe_etq'], '');
    });

    test('dt_criacao usa formato dd/MM/yyyy HH:mm:ss', () {
      final item = makeItem(dtCriacao: dtFixa);
      final json = item.toJson();
      expect(json['dt_criacao'], '15/06/2025 14:30:00');
    });

    test('sanitiza código de barras com espaços', () {
      final item = makeItem(barras: '789 123 456');
      final json = item.toJson();
      expect(json['barras'], '789123456');
    });
  });

  group('InventarioItem.fromJson', () {
    test('deserializa campos corretamente', () {
      final json = {
        'codigo': 200,
        'barras': '1234567890123',
        'produto': 'Feijão',
        'un': 'KG',
        'estoque_atual': 30.0,
        'qtd': 35.5,
        'dt_criacao': '2025-06-15T14:30:00',
      };
      final item = InventarioItem.fromJson(json, 2);

      expect(item.item, 2);
      expect(item.codigo, 200);
      expect(item.barras, '1234567890123');
      expect(item.produto, 'Feijão');
      expect(item.unidade, 'KG');
      expect(item.estoqueAtual, 30.0);
      expect(item.novoEstoque, 35.5);
    });

    test('campos ausentes usam valores padrão', () {
      final item = InventarioItem.fromJson({}, 1);
      expect(item.codigo, 0);
      expect(item.barras, '');
      expect(item.produto, '');
      expect(item.unidade, '');
      expect(item.estoqueAtual, 0.0);
      expect(item.novoEstoque, 0.0);
    });

    test('dt_criacao inválido usa DateTime.now()', () {
      final before = DateTime.now();
      final item = InventarioItem.fromJson({'dt_criacao': 'invalido'}, 1);
      final after = DateTime.now();
      expect(
        item.dtCriacao.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(item.dtCriacao.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  group('InventarioItem.validate', () {
    test('item válido retorna lista vazia', () {
      expect(makeItem().validate(), isEmpty);
    });

    test('barras vazio gera erro', () {
      expect(makeItem(barras: '').validate(), contains('barras vazio ou inválido'));
    });

    test('item <= 0 gera erro', () {
      expect(makeItem(item: 0).validate(), contains('item inválido'));
    });

    test('codigo <= 0 gera erro', () {
      expect(makeItem(codigo: 0).validate(), contains('código inválido'));
    });

    test('produto vazio gera erro', () {
      expect(makeItem(produto: '').validate(), contains('produto vazio'));
    });

    test('unidade vazia gera erro', () {
      expect(makeItem(unidade: '').validate(), contains('unidade vazia'));
    });

    test('novoEstoque negativo gera erro', () {
      expect(
        makeItem(novoEstoque: -1.0).validate(),
        contains('novoEstoque negativo'),
      );
    });
  });

  group('InventarioItem.copyWith', () {
    test('atualiza apenas campos especificados', () {
      final original = makeItem();
      final copy = original.copyWith(novoEstoque: 99.0, unidade: 'KG');

      expect(copy.novoEstoque, 99.0);
      expect(copy.unidade, 'KG');
      expect(copy.codigo, original.codigo);
      expect(copy.barras, original.barras);
      expect(copy.produto, original.produto);
    });
  });

  group('InventarioItem igualdade', () {
    test('dois itens iguais são iguais', () {
      final a = makeItem(dtCriacao: dtFixa);
      final b = makeItem(dtCriacao: dtFixa);
      expect(a, equals(b));
    });

    test('itens diferentes não são iguais', () {
      final a = makeItem(novoEstoque: 10.0);
      final b = makeItem(novoEstoque: 20.0);
      expect(a, isNot(equals(b)));
    });

    test('hashCode igual para itens iguais', () {
      final a = makeItem(dtCriacao: dtFixa);
      final b = makeItem(dtCriacao: dtFixa);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('InventarioItem.dtCriacaoFormatada', () {
    test('formata data no padrão dd/MM HH:mm', () {
      final item = makeItem(dtCriacao: dtFixa);
      expect(item.dtCriacaoFormatada, '15/06 14:30');
    });
  });

  group('InventarioRequest', () {
    test('toJson serializa coleta INVENTARIO por padrão', () {
      final req = InventarioRequest(itens: [makeItem()]);
      final json = req.toJson();
      expect(json['coleta'], 'INVENTARIO');
      expect(json['imei'], 7829);
      expect((json['itens'] as List).length, 1);
    });

    test('toJson serializa coleta ENTRADA', () {
      final req = InventarioRequest(coleta: 'ENTRADA', itens: [makeItem()]);
      final json = req.toJson();
      expect(json['coleta'], 'ENTRADA');
    });

    test('fromJson round-trip mantém dados', () {
      final original = InventarioRequest(
        coleta: 'INVENTARIO',
        imei: 1234,
        itens: [makeItem(dtCriacao: dtFixa)],
      );
      final json = original.toJson();

      // Ajusta dt_criacao para formato ISO aceito pelo fromJson
      final itensList = json['itens'] as List;
      itensList[0]['dt_criacao'] = dtFixa.toIso8601String();

      final restored = InventarioRequest.fromJson(json);
      expect(restored.coleta, original.coleta);
      expect(restored.imei, original.imei);
      expect(restored.itens.length, 1);
      expect(restored.itens.first.codigo, original.itens.first.codigo);
    });

    test('fromJson com itens nulos retorna lista vazia', () {
      final req = InventarioRequest.fromJson({'coleta': 'INVENTARIO'});
      expect(req.itens, isEmpty);
    });
  });
}
