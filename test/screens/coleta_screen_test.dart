import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/providers/config_provider.dart';
import 'package:nymbus_coletor/screens/coleta_screen.dart';
import 'package:provider/provider.dart';

ColetaScreen _coleta(List<InventarioItem> itens) {
  return ColetaScreen(
    titulo: 'Inventário',
    corPrimaria: Colors.blue,
    iconeVazio: Icons.inventory_2_outlined,
    textoListaVazia: 'Nenhum item',
    textoListaVaziaSubtitulo: 'Pesquise um código para começar',
    labelBotaoEnvio: 'Enviar',
    onCarregarItens: () async => itens,
    onSalvarItens: (_) async {},
    onLimparItens: () async {},
    onEnviarItens: (_) async {},
    mensagemItemAdicionado: 'Item adicionado',
    mensagemItemRemovido: 'Item removido',
    mensagemEnvioSucesso: 'Enviado',
    mensagemListaVazia: 'Lista vazia',
  );
}

Widget _wrap(ColetaScreen screen) {
  return ChangeNotifierProvider<ConfigProvider>(
    create: (_) => ConfigProvider(),
    child: MaterialApp(home: screen),
  );
}

InventarioItem _item() {
  return InventarioItem(
    item: 1,
    codigo: 100,
    barras: '7891234567890',
    produto: 'Arroz',
    unidade: 'UN',
    estoqueAtual: 5.0,
    novoEstoque: 6.0,
  );
}

void main() {
  testWidgets('mostra o estado vazio quando não há itens', (tester) async {
    await tester.pumpWidget(_wrap(_coleta([])));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum item'), findsOneWidget);
  });

  testWidgets('renderiza os itens carregados', (tester) async {
    await tester.pumpWidget(_wrap(_coleta([_item()])));
    await tester.pumpAndSettle();

    expect(find.text('Arroz'), findsOneWidget);
    expect(find.textContaining('Item 001'), findsOneWidget);
  });

  testWidgets('pesquisar com código vazio mostra aviso', (tester) async {
    await tester.pumpWidget(_wrap(_coleta([])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pesquisar'));
    await tester.pump(); // exibe o snackbar
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Digite um código para pesquisar'), findsOneWidget);
  });
}
