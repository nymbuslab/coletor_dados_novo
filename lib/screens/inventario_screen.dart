import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';
import 'package:nymbus_coletor/models/inventario_item.dart';
import 'package:nymbus_coletor/screens/coleta_screen.dart';
import 'package:nymbus_coletor/services/api_service.dart';
import 'package:nymbus_coletor/services/storage_service.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) => ColetaScreen(
        titulo: 'Inventário',
        corPrimaria: AppColors.inventario,
        iconeVazio: Icons.inventory,
        textoListaVazia: 'Nenhum item no inventário',
        textoListaVaziaSubtitulo:
            'Pesquise produtos para adicionar ao inventário',
        labelBotaoEnvio: 'Enviar Inventário',
        onCarregarItens: StorageService.loadInventarioItens,
        onSalvarItens: (List<InventarioItem> itens) =>
            StorageService.saveInventarioItens(itens),
        onLimparItens: StorageService.clearInventarioItens,
        onEnviarItens: (List<InventarioItem> itens) =>
            ApiService.instance.enviarInventario(itens),
        mensagemItemAdicionado: 'Item adicionado ao inventário!',
        mensagemItemRemovido: 'Item removido do inventário',
        mensagemEnvioSucesso: 'Inventário enviado com sucesso!',
        mensagemListaVazia: 'Adicione pelo menos um item ao inventário',
      );
}
