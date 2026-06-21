import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/imovel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/imovel_card.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumo = ref.watch(dashboardResumoProvider);
    final radar = ref.watch(radarProvider);
    final usuario = ref.watch(authProvider).usuario;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardResumoProvider);
          ref.invalidate(radarProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Olá, ${usuario?.nome.split(' ').first ?? 'Investidor'} 👋',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Text('Veja as melhores oportunidades de hoje',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),

            // KPIs
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: resumo.when(
                loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
                error: (e, _) => SliverToBoxAdapter(child: Text('Erro: $e')),
                data: (data) => SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 110,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    _KpiCard(
                      label: 'Total de Imóveis',
                      value: '${data['total_imoveis'] ?? 0}',
                      icon: Icons.home,
                      color: AppTheme.primary,
                    ),
                    _KpiCard(
                      label: 'No Radar',
                      value: '${data['oportunidades_excelentes'] ?? 0}',
                      icon: Icons.radar,
                      color: AppTheme.secondary,
                    ),
                    _KpiCard(
                      label: 'Desconto Médio',
                      value: '${data['desconto_medio'] ?? 0}%',
                      icon: Icons.trending_down,
                      color: AppTheme.warning,
                    ),
                    _KpiCard(
                      label: 'Próximos Leilões',
                      value: '${data['proximos_leiloes'] ?? 0}',
                      icon: Icons.event,
                      color: AppTheme.danger,
                    ),
                  ]),
                ),
              ),
            ),

            // Seção Radar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.radar, color: AppTheme.secondary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text('Radar de Oportunidades',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
                    TextButton(
                      onPressed: () => context.go('/imoveis', extra: {'no_radar': true}),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: radar.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Text('Erro: $e')),
                data: (imoveis) => imoveis.isEmpty
                    ? const SliverToBoxAdapter(
                        child: _EmptyRadar(),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 320,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ImovelCard(imovel: imoveis[i]),
                          childCount: imoveis.take(6).length,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EmptyRadar extends StatelessWidget {
  const _EmptyRadar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.radar, size: 48, color: AppTheme.secondary),
          SizedBox(height: 12),
          Text('Nenhuma oportunidade no Radar agora',
              style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('O sistema atualiza automaticamente às 6h todos os dias.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
