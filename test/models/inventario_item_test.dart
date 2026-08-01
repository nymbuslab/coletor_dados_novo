import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';

void main() {
  final dtFixa = DateTime(2025, 6, 15, 14, 30);

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
  });
}
