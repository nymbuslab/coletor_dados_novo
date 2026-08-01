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

  // Criação a partir de JSON (se necessário)
  factory InventarioItem.fromJson(Map<String, dynamic> json, int itemNumber) {
    // Parse defensivo: tolera número vindo como string, nulo ou ausente
    // (a API é inconsistente de tipos). Para o JSON atual, resultado idêntico.
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    return InventarioItem(
      item: itemNumber,
      codigo: parseInt(json['codigo']),
      barras: BarcodeUtils.sanitize((json['barras'] ?? '').toString()),
      produto: (json['produto'] ?? '').toString(),
      unidade: (json['un'] ?? '').toString(),
      estoqueAtual: parseDouble(json['estoque_atual']),
      novoEstoque: parseDouble(json['qtd']),
      dtCriacao: json['dt_criacao'] != null
          ? DateTime.tryParse(json['dt_criacao'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Método copyWith para criar cópias com modificações
  InventarioItem copyWith({
    int? item,
    int? codigo,
    String? barras,
    String? produto,
    String? unidade,
    double? estoqueAtual,
    double? novoEstoque,
    DateTime? dtCriacao,
  }) {
    return InventarioItem(
      item: item ?? this.item,
      codigo: codigo ?? this.codigo,
      barras: barras ?? this.barras,
      produto: produto ?? this.produto,
      unidade: unidade ?? this.unidade,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      novoEstoque: novoEstoque ?? this.novoEstoque,
      dtCriacao: dtCriacao ?? this.dtCriacao,
    );
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

  factory InventarioRequest.fromJson(Map<String, dynamic> json) {
    return InventarioRequest(
      coleta: json['coleta'] ?? 'INVENTARIO',
      imei: json['imei'] ?? 7829,
      itens:
          (json['itens'] as List<dynamic>?)
              ?.asMap()
              .entries
              .map(
                (entry) => InventarioItem.fromJson(entry.value, entry.key + 1),
              )
              .toList() ??
          [],
    );
  }
}
