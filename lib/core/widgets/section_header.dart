import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';

/// Cabeçalho de seção/tela com o título grande "Apple tight" (ver
/// `DESIGN-apple.md`): headline em peso 600 com tracking negativo, opcionalmente
/// seguido de um subtítulo em tinta suave.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tt.headlineMedium!.copyWith(color: AppColors.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: tt.bodyLarge!.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
