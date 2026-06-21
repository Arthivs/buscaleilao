import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/imovel_provider.dart';

// Centro de Aracaju/SE
const _aracajuCenter = LatLng(-10.9472, -37.0731);

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  Map<String, dynamic>? _selecionado;

  @override
  Widget build(BuildContext context) {
    final mapaData = ref.watch(mapaImoveisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Oportunidades'),
        actions: [
          mapaData.whenOrNull(
            data: (items) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${items.length} imóveis',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: mapaData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar mapa: $e')),
        data: (imoveis) => Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _aracajuCenter,
                initialZoom: 12.5,
                onTap: (_, __) => setState(() => _selecionado = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.leilaointeligente.app',
                ),
                MarkerLayer(
                  markers: imoveis
                      .where((i) => i['lat'] != null && i['lng'] != null)
                      .map((i) => Marker(
                            point: LatLng(i['lat'], i['lng']),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => setState(() => _selecionado = i),
                              child: _MapMarker(
                                score: (i['score'] as num?)?.toDouble() ?? 0,
                                noRadar: i['no_radar'] == true,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),

            // Painel de informação do imóvel selecionado
            if (_selecionado != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _InfoPanel(
                  imovel: _selecionado!,
                  onFechar: () => setState(() => _selecionado = null),
                  onAbrir: () => context.go('/imoveis/${_selecionado!['id']}'),
                ),
              ),

            // Legenda
            Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Score', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      _LegendaItem(AppTheme.secondary, '80–100 (Excelente)'),
                      _LegendaItem(AppTheme.primary, '60–79 (Bom)'),
                      _LegendaItem(AppTheme.warning, '40–59 (Moderado)'),
                      _LegendaItem(AppTheme.danger, '< 40 (Risco)'),
                    ],
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

class _MapMarker extends StatelessWidget {
  final double score;
  final bool noRadar;
  const _MapMarker({required this.score, required this.noRadar});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)],
          ),
          child: Icon(
            noRadar ? Icons.radar : Icons.home,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final Map<String, dynamic> imovel;
  final VoidCallback onFechar;
  final VoidCallback onAbrir;

  const _InfoPanel({required this.imovel, required this.onFechar, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final score = (imovel['score'] as num?)?.toDouble() ?? 0;
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.scoreColor(score),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Score ${score.toInt()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onFechar,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(imovel['endereco'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (imovel['bairro'] != null)
              Text(imovel['bairro'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (imovel['valor_lance'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        Text('R\$ ${(imovel['valor_lance'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (imovel['lucro_potencial'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lucro potencial', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        Text('R\$ ${(imovel['lucro_potencial'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondary)),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: onAbrir,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Ver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendaItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
