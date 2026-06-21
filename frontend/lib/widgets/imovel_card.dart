import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/imovel.dart';
import '../core/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _pct = NumberFormat.decimalPercentPattern(locale: 'pt_BR', decimalDigits: 1);

class ImovelCard extends StatelessWidget {
  final Imovel imovel;
  final VoidCallback? onFavoritar;

  const ImovelCard({super.key, required this.imovel, this.onFavoritar});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/imoveis/${imovel.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header colorido com score e radar badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.scoreColor(imovel.score).withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScoreBadge(score: imovel.score),
                  if (imovel.noRadar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('RADAR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      imovel.isFavorito ? Icons.favorite : Icons.favorite_border,
                      color: imovel.isFavorito ? AppTheme.danger : AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: onFavoritar,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo e ocupação
                  Row(children: [
                    _Tag(imovel.tipo.toUpperCase()),
                    const SizedBox(width: 6),
                    if (imovel.ocupado)
                      _Tag('OCUPADO', color: AppTheme.warning),
                  ]),
                  const SizedBox(height: 10),

                  // Endereço
                  Text(
                    imovel.endereco,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (imovel.bairro != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${imovel.bairro} • ${imovel.cidade}/${imovel.estado}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Valores
                  Row(children: [
                    Expanded(child: _ValorItem('Lance mínimo', _brl.format(imovel.valorLance))),
                    Expanded(child: _ValorItem('Mercado est.', imovel.valorMercado != null ? _brl.format(imovel.valorMercado) : '-')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _ValorItem('Desconto', imovel.desconto != null ? '${imovel.desconto!.toStringAsFixed(1)}%' : '-', highlight: true)),
                    Expanded(child: _ValorItem('Lucro potencial', imovel.lucroPotencial != null ? _brl.format(imovel.lucroPotencial) : '-', highlight: true)),
                  ]),

                  if (imovel.dataLeilao != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.event, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Leilão: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(imovel.dataLeilao!)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ]),
                  ],

                  if (imovel.areaConstuida != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.square_foot, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${imovel.areaConstuida!.toStringAsFixed(0)} m²',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Score ${score.toStringAsFixed(0)}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, {this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ValorItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _ValorItem(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: highlight ? AppTheme.secondary : AppTheme.text,
          ),
        ),
      ],
    );
  }
}
