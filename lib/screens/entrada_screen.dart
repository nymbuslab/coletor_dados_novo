import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/screens/coleta_screen.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/storage_service.dart';

class EntradaScreen extends StatelessWidget {
  const EntradaScreen({super.key});

  @override
  Widget build(BuildContext context) => ColetaScreen(
        titulo: 'Entrada',
        corPrimaria: AppColors.entrada,
        iconeVazio: Icons.input,
        textoListaVazia: 'Nenhum item na entrada',
        textoListaVaziaSubtitulo:
            'Pesquise produtos para adicionar à entrada',
        labelBotaoEnvio: 'Enviar Entrada',
        onCarregarItens: StorageService.loadEntradaItens,
        onSalvarItens: StorageService.saveEntradaItens,
        onLimparItens: StorageService.clearEntradaItens,
        onEnviarItens: (List<InventarioItem> itens) =>
            ApiService.instance.enviarEntrada(itens),
        mensagemItemAdicionado: 'Item adicionado à entrada!',
        mensagemItemRemovido: 'Item removido da entrada',
        mensagemEnvioSucesso: 'Entrada enviada com sucesso!',
        mensagemListaVazia: 'Adicione pelo menos um item à entrada',
      );
}
