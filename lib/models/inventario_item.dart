import 'package:intl/intl.dart';
import 'package:nymbus_coletor/utils/barcode_utils.dart';

class InventarioItem {
  final int item;
  final int codigo;
  final String barras;
  final String produto;
  final String unidade;
  final double estoqueAtual;
  final double novoEstoque;
  final DateTime dtCriacao;

  InventarioItem({
    required this.item,
    required this.codigo,
    required this.barras,
    required this.produto,
    required this.unidade,
    required this.estoqueAtual,
    required this.novoEstoque,
    DateTime? dtCriacao,
  }) : dtCriacao = dtCriacao ?? DateTime.now();

  // Formatação da data/hora para exibição
  String get dtCriacaoFormatada {
    return DateFormat('dd/MM HH:mm').format(dtCriacao);
  }

  // Conversão para JSON para envio à API
  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'barras': BarcodeUtils.sanitize(barras),
      'produto': produto,
      'un': unidade,
      'qtd': novoEstoque,
      'dt_criacao': DateFormat('dd/MM/yyyy HH:mm:ss').format(dtCriacao),
      'danfe_etq': '',
    };
  }

  // Validação sistemática do modelo
  List<String> validate() {
    final errors = <String>[];
    final b = BarcodeUtils.sanitize(barras);
    if (b.isEmpty) errors.add('barras vazio ou inválido');
    if (item <= 0) errors.add('item inválido');
    if (codigo <= 0) errors.add('código inválido');
    if (produto.trim().isEmpty) errors.add('produto vazio');
    if (unidade.trim().isEmpty) errors.add('unidade vazia');
    if (novoEstoque < 0) errors.add('novoEstoque negativo');
    return errors;
  }

  @override
  String toString() {
    return 'InventarioItem(item: $item, codigo: $codigo, barras: $barras, produto: $produto, unidade: $unidade, estoqueAtual: $estoqueAtual, novoEstoque: $novoEstoque, dtCriacao: $dtCriacao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventarioItem &&
        other.item == item &&
        other.codigo == codigo &&
        other.barras == barras &&
        other.produto == produto &&
        other.unidade == unidade &&
        other.estoqueAtual == estoqueAtual &&
        other.novoEstoque == novoEstoque &&
        other.dtCriacao == dtCriacao;
  }

  @override
  int get hashCode {
    return Object.hash(
      item,
      codigo,
      barras,
      produto,
      unidade,
      estoqueAtual,
      novoEstoque,
      dtCriacao,
    );
  }
}

class InventarioRequest {
  final String coleta;
  final int imei;
  final List<InventarioItem> itens;

  InventarioRequest({
    this.coleta = 'INVENTARIO',
    this.imei = 7829,
    required this.itens,
  });

  Map<String, dynamic> toJson() {
    return {
      'coleta': coleta,
      'imei': imei,
      'itens': itens.map((item) => item.toJson()).toList(),
    };
  }
}
