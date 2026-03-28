import 'package:flutter/material.dart';
import 'package:nymbus_coletor/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _abrirEtiqueta() => Navigator.of(context).pushNamed('/etiqueta');
  void _abrirConsultaPreco() => Navigator.of(context).pushNamed('/consulta');
  void _abrirInventario() => Navigator.of(context).pushNamed('/inventario');
  void _irParaConfiguracoes() =>
      Navigator.of(context).pushNamed('/config', arguments: 'home');

  void _voltarParaLogin() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coletor de Dados'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _voltarParaLogin,
          tooltip: 'Voltar para Login',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _irParaConfiguracoes,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 56,
                        color: AppColors.seed.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Coletor de Dados',
                      style: tt.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecione uma operação para começar',
                      style: tt.bodyMedium!.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Cards de ação
                    _ActionCard(
                      icon: Icons.label_outline,
                      color: AppColors.etiqueta,
                      title: 'Etiqueta',
                      description: 'Pesquise e imprima etiquetas de produtos',
                      onTap: _abrirEtiqueta,
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.search,
                      color: AppColors.consulta,
                      title: 'Consulta Preço',
                      description: 'Consulte preço, estoque e dados do produto',
                      onTap: _abrirConsultaPreco,
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.inventario,
                      title: 'Inventário',
                      description: 'Faça a contagem e envie o inventário',
                      onTap: _abrirInventario,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: tt.bodySmall!.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
