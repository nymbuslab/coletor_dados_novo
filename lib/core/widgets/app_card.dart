import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';

/// Card do design system "Apple" (ver `DESIGN-apple.md`): raio 18, hairline
/// 1px e **sem sombra** — no sistema Apple o chrome não tem elevação; a única
/// sombra é reservada a foto de produto (que o app não tem).
///
/// Se [onTap] for informado, ganha ripple dentro do próprio raio.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.canvas,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      side: BorderSide(color: AppColors.border),
    );

    final inner = Padding(padding: padding, child: child);

    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? inner
          : InkWell(customBorder: shape, onTap: onTap, child: inner),
    );
  }
}
