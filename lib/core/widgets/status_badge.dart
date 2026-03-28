import 'package:flutter/material.dart';

/// Badge pill reutilizável para status, categorias e quantidades.
///
/// Uso:
/// ```dart
/// StatusBadge(label: 'Novo: 15', color: AppColors.success)
/// StatusBadge(label: 'UN', color: AppColors.info)
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.overflow = TextOverflow.ellipsis,
  });

  final String label;
  final Color color;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: tt.labelMedium!.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        overflow: overflow,
      ),
    );
  }
}
