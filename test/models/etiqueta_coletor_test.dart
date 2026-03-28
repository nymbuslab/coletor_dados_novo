import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/etiqueta_coletor.dart';

void main() {
  group('EtiquetaColetor.fromProduto', () {
    test('popula campos corretamente', () {
      final etq = EtiquetaColetor.fromProduto(
        codProduto: '001',
        codBarras: '7891234567890',
        nomeProduto: 'Arroz',
        unidade: 'UN',
        tipoEtiqueta: 'GONDOLA GRANDE',
        quantidade: 3,
        preco: '12,50',
      );

      expect(etq.etqCodmat, '001');
      expect(etq.etqEan13, '7891234567890');
      expect(etq.etqDesc, 'Arroz');
      expect(etq.etqUn, 'UN');
      expect(etq.layetqText, 'GONDOLA GRANDE');
      expect(etq.etqQtd, 3);
      expect(etq.etqPreco, '12,50');
    });

    test('quantidade padrão é 1', () {
      final etq = EtiquetaColetor.fromProduto(
        codProduto: '002',
        codBarras: '123',
        nomeProduto: 'Feijão',
        unidade: 'KG',
        tipoEtiqueta: 'PRATELEIRA',
      );
      expect(etq.etqQtd, 1);
    });

    test('etqDthora é preenchido com data atual', () {
      final before = DateTime.now();
      final etq = EtiquetaColetor.fromProduto(
        codProduto: '003',
        codBarras: '456',
        nomeProduto: 'Sal',
        unidade: 'UN',
        tipoEtiqueta: 'X',
      );
      expect(etq.etqDthora, isNotNull);
      expect(etq.etqDthora!.length, greaterThan(10));

      // Verifica que contém dia/mês/ano do momento atual
      final day = before.day.toString().padLeft(2, '0');
      final month = before.month.toString().padLeft(2, '0');
      expect(etq.etqDthora, contains('$day/$month/${before.year}'));
    });
  });

  group('EtiquetaColetor.toJson', () {
    test('serializa campos obrigatórios', () {
      final etq = EtiquetaColetor(
        etqCodmat: '001',
        etqEan13: '7891234567890',
        etqDesc: 'Arroz',
        etqUn: 'UN',
        etqQtd: 2,
        layetqText: 'GONDOLA GRANDE',
      );
      final json = etq.toJson();

      expect(json['ETQ_CODMAT'], '001');
      expect(json['ETQ_EAN13'], '7891234567890');
      expect(json['ETQ_DESC'], 'Arroz');
      expect(json['ETQ_UN'], 'UN');
      expect(json['ETQ_QTD'], 2);
      expect(json['LAYETQ_TEXT'], 'GONDOLA GRANDE');
      expect(json['gr7_status'], 'A');
    });

    test('campos nulos usam valores padrão', () {
      final etq = EtiquetaColetor();
      final json = etq.toJson();

      expect(json['ETQ_CODMAT'], '');
      expect(json['ETQ_EAN13'], '');
      expect(json['ETQ_DESC'], '');
      expect(json['ETQ_UN'], '');
      expect(json['ETQ_QTD'], 1);
      expect(json['ETQ_VAL'], '0');
      expect(json['ETQ_PRECO'], '0');
    });
  });

  group('EtiquetaColetor.fromJson', () {
    test('deserializa campos corretamente', () {
      final json = {
        'ETQ_IDX': 10,
        'ETQ_ID': 5,
        'LOTE_ID': 1,
        'ETQ_CODMAT': '001',
        'ETQ_QTD': 3,
        'ETQ_EAN13': '7891234567890',
        'ETQ_DTHORA': '15/06/2025 10:30:00',
        'ETQ_DESC': 'Arroz',
        'ETQ_UN': 'UN',
        'LAYETQ_TEXT': 'GONDOLA GRANDE',
        'gr7_status': 'A',
      };
      final etq = EtiquetaColetor.fromJson(json);

      expect(etq.etqIdx, 10);
      expect(etq.etqId, 5);
      expect(etq.loteId, 1);
      expect(etq.etqCodmat, '001');
      expect(etq.etqQtd, 3);
      expect(etq.etqEan13, '7891234567890');
      expect(etq.etqDesc, 'Arroz');
      expect(etq.gr7Status, 'A');
    });
  });

  group('EtiquetaColetor.toString', () {
    test('inclui campos principais', () {
      final etq = EtiquetaColetor(
        etqCodmat: '001',
        etqDesc: 'Sal',
        etqQtd: 5,
        layetqText: 'PRATELEIRA',
      );
      final s = etq.toString();
      expect(s, contains('001'));
      expect(s, contains('Sal'));
      expect(s, contains('5'));
      expect(s, contains('PRATELEIRA'));
    });
  });
}
