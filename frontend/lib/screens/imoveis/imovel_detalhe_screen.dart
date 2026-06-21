import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/imovel_provider.dart';
import '../../models/imovel.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ImovelDetalheScreen extends ConsumerWidget {
  final int imovelId;
  const ImovelDetalheScreen({super.key, required this.imovelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalhe = ref.watch(imovelDetalheProvider(imovelId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Detalhes do Imóvel'),
        actions: [
          detalhe.whenOrNull(
            data: (im) => IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Simular investimento',
              onPressed: () => context.go('/simulador?imovel_id=${im.id}'),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: detalhe.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (im) => _DetalheBody(imovel: im),
      ),
    );
  }
}

class _DetalheBody extends StatelessWidget {
  final Imovel imovel;
  const _DetalheBody({required this.imovel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.scoreColor(imovel.score),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Score ${imovel.score.toStringAsFixed(0)}/100',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (imovel.noRadar)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radar, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('NO RADAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(imovel.endereco, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  if (imovel.bairro != null)
                    Text('${imovel.bairro} • ${imovel.cidade}/${imovel.estado}',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Valores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Valores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _Row('Valor de Avaliação', _brl.format(imovel.valorAvaliacao)),
                  _Row('Lance Mínimo', _brl.format(imovel.valorLance), bold: true),
                  if (imovel.valorMercado != null)
                    _Row('Valor de Mercado Estimado', _brl.format(imovel.valorMercado), color: AppTheme.primary),
                  if (imovel.desconto != null)
                    _Row('Desconto Estimado', '${imovel.desconto!.toStringAsFixed(1)}%', color: AppTheme.secondary, bold: true),
                  if (imovel.lucroPotencial != null)
                    _Row('Lucro Potencial', _brl.format(imovel.lucroPotencial), color: AppTheme.secondary, bold: true),
                  if (imovel.roi != null)
                    _Row('ROI Estimado', '${imovel.roi!.toStringAsFixed(1)}%', color: AppTheme.secondary),
                  if (imovel.paybackMeses != null)
                    _Row('Payback Estimado', '${imovel.paybackMeses} meses'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Características
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Características', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _Row('Tipo', imovel.tipo.toUpperCase()),
                  if (imovel.areaConstuida != null) _Row('Área Construída', '${imovel.areaConstuida!.toStringAsFixed(0)} m²'),
                  if (imovel.areaTereno != null) _Row('Área do Terreno', '${imovel.areaTereno!.toStringAsFixed(0)} m²'),
                  _Row('Situação', imovel.ocupado ? '🔴 Ocupado' : '🟢 Desocupado'),
                  _Row('Fonte', imovel.fonte.toUpperCase()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Datas
          if (imovel.dataLeilao != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    _Row('Data do Leilão', DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(imovel.dataLeilao!)),
                    const SizedBox(height: 8),
                    const Text('⚠️ Confirme a data no edital oficial antes de licitar.',
                        style: TextStyle(fontSize: 12, color: AppTheme.warning)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Análise IA
          if (imovel.analiseIA != null) ...[
            _AnaliseIACard(analise: imovel.analiseIA!),
            const SizedBox(height: 12),
          ],

          // Links
          if (imovel.urlEdital != null || imovel.urlImovel != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (imovel.urlEdital != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Ver Edital Completo'),
                        onPressed: () => launchUrl(Uri.parse(imovel.urlEdital!)),
                      ),
                    if (imovel.urlImovel != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver na Fonte Original'),
                        onPressed: () => launchUrl(Uri.parse(imovel.urlImovel!)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.calculate),
            label: const Text('Simular Investimento'),
            onPressed: () => GoRouter.of(context).go('/simulador?imovel_id=${imovel.id}'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppTheme.text,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnaliseIACard extends StatelessWidget {
  final AnaliseIA analise;
  const _AnaliseIACard({required this.analise});

  Color get _corClassificacao {
    switch (analise.classificacao) {
      case 'excelente': return AppTheme.secondary;
      case 'boa': return AppTheme.primary;
      case 'moderada': return AppTheme.warning;
      default: return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Análise IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (analise.classificacao != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _corClassificacao.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    analise.classificacao!.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(color: _corClassificacao, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ]),

            if (analise.resumoExecutivo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(analise.resumoExecutivo!,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ],

            if (analise.pontosPositivos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('✅ Pontos Positivos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...analise.pontosPositivos.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppTheme.secondary)),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],

            if (analise.pontosAtencao.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('⚠️ Pontos de Atenção', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...analise.pontosAtencao.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppTheme.warning)),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],

            if (analise.riscos.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('⚖️ Riscos Jurídicos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...analise.riscos.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppTheme.danger)),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],

            if (analise.recomendacaoFinal != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _corClassificacao.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _corClassificacao.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recomendação Final', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(analise.recomendacaoFinal!, style: const TextStyle(fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Text('⚠️ Esta análise é gerada por IA e não substitui consultoria jurídica e imobiliária profissional.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
