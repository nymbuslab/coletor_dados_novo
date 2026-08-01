import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';

/// Variantes da gramática de botão-pílula "Apple".
enum AppPillVariant {
  /// Pílula cheia Action Blue, texto branco. A ação principal.
  primary,

  /// Pílula fantasma: borda Action Blue, fundo transparente, texto azul.
  secondary,
}

/// Botão-pílula do design system (ver `DESIGN-apple.md`).
///
/// Centraliza a gramática de ação: cápsula (`StadiumBorder`), Action Blue e o
/// micro-scale 0.95 no toque — a micro-interação padrão do sistema Apple.
///
/// ```dart
/// AppPillButton(label: 'Salvar', onPressed: _salvar)
/// AppPillButton(label: 'Cancelar', variant: AppPillVariant.secondary, onPressed: _voltar)
/// ```
class AppPillButton extends StatefulWidget {
  const AppPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppPillVariant.primary,
    this.expand = true,
  });

  final String label;

  /// `null` desabilita o botão.
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppPillVariant variant;

  /// Ocupa toda a largura disponível (padrão). `false` = encolhe ao conteúdo.
  final bool expand;

  @override
  State<AppPillButton> createState() => _AppPillButtonState();
}

class _AppPillButtonState extends State<AppPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final isPrimary = widget.variant == AppPillVariant.primary;

    final Color bg;
    final Color fg;
    final BorderSide side;
    if (isPrimary) {
      bg = enabled ? AppColors.action : AppColors.action.withValues(alpha: 0.4);
      fg = Colors.white;
      side = BorderSide.none;
    } else {
      bg = Colors.transparent;
      fg = enabled ? AppColors.action : AppColors.inkMuted;
      side = BorderSide(color: fg);
    }

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.374,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: side),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: widget.onPressed,
          onHighlightChanged: (v) {
            if (enabled) setState(() => _pressed = v);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Center(widthFactor: widget.expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
