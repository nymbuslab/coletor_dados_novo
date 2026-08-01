import 'package:flutter/material.dart';

enum FeedbackType { info, success, error, warning }

class FeedbackService {
  static void showSnack(
    BuildContext context,
    String message, {
    FeedbackType type = FeedbackType.info,
    Duration? duration,
  }) {
    final color = _colorFor(type);
    final snack = SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    );
    final messenger = ScaffoldMessenger.of(context);
    // Remove o snackbar anterior para não empilhar mensagens.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snack);
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = 'Erro',
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Traduz um erro técnico (Exception, timeout, rede, HTTP) em mensagem
  /// amigável em português para exibir ao usuário. O detalhe técnico deve
  /// continuar indo para o log (LoggerService), não para a tela.
  static String friendlyError(Object error) {
    final s = error.toString().toLowerCase();
    bool has(String needle) => s.contains(needle);

    if (has('timeout') || has('esgotado')) {
      return 'Erro: tempo de conexão esgotado. Tente novamente.';
    }
    if (has('socketexception') ||
        has('failed host lookup') ||
        has('failed to fetch') ||
        has('xmlhttprequest') ||
        has('connection refused') ||
        has('network') ||
        has('sem conexão')) {
      return 'Erro: sem conexão com o servidor. Verifique o endereço, a porta e a rede.';
    }
    if (has('401') ||
        has('403') ||
        has('unauthorized') ||
        has('forbidden') ||
        has('não autorizado') ||
        has('nao autorizado')) {
      return 'Falha de autorização. Valide sua licença novamente.';
    }
    if (has('500') ||
        has('502') ||
        has('503') ||
        has('504') ||
        has('erro do servidor') ||
        has('erro http 5')) {
      return 'Erro no servidor. Tente novamente em instantes.';
    }
    if (has('formatexception') ||
        has('formato') ||
        has('json') ||
        has('decodificar')) {
      return 'Erro ao ler a resposta do servidor.';
    }
    return 'Falha ao concluir a operação. Tente novamente.';
  }

  /// Heurística simples para classificar a mensagem e aplicar cor adequada
  static FeedbackType classifyMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('erro') ||
        m.contains('não encontrado') ||
        m.contains('inexistente') ||
        m.contains('falha')) {
      return FeedbackType.error;
    }
    if (m.contains('sucesso') ||
        m.contains('adicionado') ||
        m.contains('removido') ||
        m.contains('atualizado') ||
        m.contains('enviado')) {
      return FeedbackType.success;
    }
    if (m.contains('atenção') ||
        m.contains('aviso') ||
        m.contains('selecione') ||
        m.contains('adicione')) {
      return FeedbackType.warning;
    }
    return FeedbackType.info;
  }

  static Color _colorFor(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green.shade600;
      case FeedbackType.error:
        return Colors.red.shade700;
      case FeedbackType.warning:
        return Colors.orange.shade700;
      case FeedbackType.info:
        return Colors.blueGrey.shade600;
    }
  }

  // Alerta didático para orientar o usuário a validar a conexão
  static Future<void> showConfigRequiredDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conexão não validada'),
        content: const Text(
          'Para usar esta função, valide a conexão nas Configurações:\n\n'
          '1) Informe o endereço e a porta do servidor\n'
          '2) Toque em Sincronizar e valide sua licença\n\n'
          'Você pode fazer isso agora tocando no botão abaixo.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              final navigator = Navigator.of(context);
              navigator.pushNamed('/config', arguments: 'home');
            },
            icon: const Icon(Icons.settings),
            label: const Text('Ir para Configurações'),
          ),
        ],
      ),
    );
  }
}
