import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/produto.dart';

void main() {
  group('Produto.fromJson', () {
    test('parseia campos básicos corretamente', () {
      final json = {
        'cod_barras': '7891234567890',
        'cod_produto': '001',
        'produto': 'Arroz Tipo 1',
        'unidade': 'UN',
        'valor_venda1': 12.50,
        'qtd_estoque': 100.0,
      };
      final p = Produto.fromJson(json, 1);

      expect(p.codBarras, '7891234567890');
      expect(p.codProduto, '001');
      expect(p.produto, 'Arroz Tipo 1');
      expect(p.unidade, 'UN');
      expect(p.valorVenda, 12.50);
      expect(p.qtdEstoque, 100.0);
      expect(p.numeroItem, 1);
    });

    test('aceita valor_venda como fallback de valor_venda1', () {
      final json = {
        'cod_barras': '123',
        'cod_produto': '002',
        'produto': 'Feijão',
        'unidade': 'KG',
        'valor_venda': 8.90,
      };
      final p = Produto.fromJson(json, 2);
      expect(p.valorVenda, 8.90);
    });

    test('converte valor_venda String para double', () {
      final json = {
        'cod_barras': '456',
        'cod_produto': '003',
        'produto': 'Macarrão',
        'unidade': 'CX',
        'valor_venda1': '5,99',
      };
      final p = Produto.fromJson(json, 3);
      expect(p.valorVenda, 5.99);
    });

    test('converte valor_venda int para double', () {
      final json = {
        'cod_barras': '789',
        'cod_produto': '004',
        'produto': 'Óleo',
        'unidade': 'LT',
        'valor_venda1': 10,
      };
      final p = Produto.fromJson(json, 4);
      expect(p.valorVenda, 10.0);
    });

    test('campos nulos resultam em valores padrão', () {
      final json = {
        'cod_barras': null,
        'cod_produto': null,
        'produto': null,
        'unidade': null,
        'valor_venda1': null,
      };
      final p = Produto.fromJson(json, 5);
      expect(p.codBarras, '');
      expect(p.codProduto, '');
      expect(p.produto, '');
      expect(p.unidade, '');
      expect(p.valorVenda, 0.0);
    });
  });

  group('Produto.validate', () {
    test('produto válido retorna lista vazia', () {
      final p = Produto(
        codBarras: '7891234567890',
        codProduto: '001',
        produto: 'Arroz',
        unidade: 'UN',
        valorVenda: 10.0,
        dataHoraRequisicao: DateTime.now(),
        numeroItem: 1,
      );
      expect(p.validate(), isEmpty);
    });

    test('codBarras vazio gera erro', () {
      final p = Produto(
        codBarras: '',
        codProduto: '001',
        produto: 'Arroz',
        unidade: 'UN',
        valorVenda: 10.0,
        dataHoraRequisicao: DateTime.now(),
        numeroItem: 1,
      );
      expect(p.validate(), contains('codBarras vazio ou inválido'));
    });

    test('valorVenda negativo gera erro', () {
      final p = Produto(
        codBarras: '123',
        codProduto: '001',
        produto: 'Arroz',
        unidade: 'UN',
        valorVenda: -1.0,
        dataHoraRequisicao: DateTime.now(),
        numeroItem: 1,
      );
      expect(p.validate(), contains('valorVenda negativo'));
    });

    test('produto vazio gera erro', () {
      final p = Produto(
        codBarras: '123',
        codProduto: '001',
        produto: '',
        unidade: 'UN',
        valorVenda: 5.0,
        dataHoraRequisicao: DateTime.now(),
        numeroItem: 1,
      );
      expect(p.validate(), contains('produto vazio'));
    });
  });

  group('Produto formatters', () {
    late Produto produto;

    setUp(() {
      produto = Produto(
        codBarras: '7891234567890',
        codProduto: '001',
        produto: 'Arroz',
        unidade: 'UN',
        valorVenda: 12.5,
        dataHoraRequisicao: DateTime(2025, 6, 15, 10, 30),
        numeroItem: 7,
        qtdEstoque: 50.0,
        valorCompra: 9.99,
        dataAtualizacao: '2025-06-10T00:00:00',
      );
    });

    test('precoFormatado usa vírgula', () {
      expect(produto.precoFormatado, 'R\$ 12,50');
    });

    test('valorCompraFormatado formata com vírgula', () {
      expect(produto.valorCompraFormatado, 'R\$ 9,99');
    });

    test('valorCompraFormatado retorna N/A quando nulo', () {
      final p = produto.toJson();
      p['valor_compra'] = null;
      final semCompra = Produto.fromJson(p, 1);
      expect(semCompra.valorCompraFormatado, 'N/A');
    });

    test('numeroItemFormatado com padding de zeros', () {
      expect(produto.numeroItemFormatado, 'Item 007');
    });

    test('dataHoraFormatada formata corretamente', () {
      final formatted = produto.dataHoraFormatada;
      expect(formatted, contains('15/06/2025'));
      expect(formatted, contains('10:30'));
    });

    test('qtdEstoqueFormatada usa vírgula', () {
      expect(produto.qtdEstoqueFormatada, '50,00');
    });

    test('qtdEstoqueFormatada retorna N/A quando nulo', () {
      final p = Produto(
        codBarras: '123',
        codProduto: '001',
        produto: 'Arroz',
        unidade: 'UN',
        valorVenda: 5.0,
        dataHoraRequisicao: DateTime.now(),
        numeroItem: 1,
      );
      expect(p.qtdEstoqueFormatada, 'N/A');
    });

    test('dataAtualizacaoFormatada converte ISO para dd/MM/yyyy', () {
      expect(produto.dataAtualizacaoFormatada, '10/06/2025');
    });

    test('dataAtualizacaoFormatada retorna N/A quando nula', () {
      final p = Produto(
        codBarras: '123',
        codProduto: '001',
        produto: 'X',
        unidade: 'UN',
        valorVenda: 1.0,
        dataHoraRequisicao: DateTime.now(),
        numeroItem: 1,
      );
      expect(p.dataAtualizacaoFormatada, 'N/A');
    });
  });

  group('TipoEtiqueta', () {
    test('fromJson mapeia campos da API corretamente', () {
      final json = {
        'codigo': '5',
        'etiqueta': 'Gondola Grande',
        'arquivo': 'gondola_grande.btw',
      };
      final t = TipoEtiqueta.fromJson(json);
      expect(t.id, '5');
      expect(t.nome, 'Gondola Grande');
      expect(t.descricao, 'gondola_grande.btw');
    });

    test('toJson round-trip mantém valores', () {
      final original = TipoEtiqueta(
        id: '3',
        nome: 'Prateleira',
        descricao: 'prateleira.btw',
      );
      final json = original.toJson();
      final restored = TipoEtiqueta.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.nome, original.nome);
      expect(restored.descricao, original.descricao);
    });

    test('toString retorna nome', () {
      final t = TipoEtiqueta(id: '1', nome: 'Etiqueta X', descricao: '');
      expect(t.toString(), 'Etiqueta X');
    });
  });
}
