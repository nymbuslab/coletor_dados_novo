import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';

/// Estado vazio padronizado para listas e telas sem conteúdo.
///
/// Uso:
/// ```dart
/// EmptyState(
///   icon: Icons.inventory,
///   color: AppColors.inventario,
///   title: 'Nenhum item',
///   subtitle: 'Pesquise um produto para começar',
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = AppColors.inkMuted,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: color.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: tt.titleMedium!.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: tt.bodyMedium!.copyWith(color: AppColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
