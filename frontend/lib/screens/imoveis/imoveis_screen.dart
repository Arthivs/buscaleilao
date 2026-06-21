import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/imovel_provider.dart';
import '../../widgets/imovel_card.dart';
import '../../core/api_client.dart';

class ImoveisScreen extends ConsumerWidget {
  const ImoveisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(imoveisProvider);
    final filtros = ref.watch(filtrosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imóveis em Leilão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _mostrarFiltros(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(imoveisProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros ativos
          if (_temFiltros(filtros))
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (filtros.bairro != null) _FilterChip('Bairro: ${filtros.bairro}', ref),
                  if (filtros.tipo != null) _FilterChip('Tipo: ${filtros.tipo}', ref),
                  if (filtros.scoreMin != null) _FilterChip('Score ≥ ${filtros.scoreMin}', ref),
                  if (filtros.noRadar == true) _FilterChip('No Radar', ref),
                  if (filtros.ocupado != null) _FilterChip(filtros.ocupado! ? 'Ocupado' : 'Desocupado', ref),
                ],
              ),
            ),

          Expanded(
            child: lista.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                    const SizedBox(height: 8),
                    Text('Erro ao carregar: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(imoveisProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (resp) => resp.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text('Nenhum imóvel encontrado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Tente ajustar os filtros', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${resp.total} imóveis encontrados',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              Text('Página ${resp.page} de ${resp.pages}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 380,
                              mainAxisExtent: 330,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: resp.items.length,
                            itemBuilder: (context, i) {
                              final imovel = resp.items[i];
                              return ImovelCard(
                                imovel: imovel,
                                onFavoritar: () async {
                                  final api = ref.read(apiClientProvider);
                                  await api.post('/imoveis/${imovel.id}/favoritar');
                                  ref.invalidate(imoveisProvider);
                                },
                              );
                            },
                          ),
                        ),
                        // Paginação
                        if (resp.pages > 1)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: filtros.page > 1
                                      ? () => ref.read(filtrosProvider.notifier).state =
                                          filtros.copyWith(page: filtros.page - 1)
                                      : null,
                                ),
                                Text('${filtros.page} / ${resp.pages}'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: filtros.page < resp.pages
                                      ? () => ref.read(filtrosProvider.notifier).state =
                                          filtros.copyWith(page: filtros.page + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _temFiltros(FiltrosState f) =>
      f.bairro != null || f.tipo != null || f.scoreMin != null || f.noRadar != null || f.ocupado != null;

  void _mostrarFiltros(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FiltrosSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final WidgetRef ref;
  const _FilterChip(this.label, this.ref);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: () {
          ref.read(filtrosProvider.notifier).state = const FiltrosState();
        },
      ),
    );
  }
}

class _FiltrosSheet extends ConsumerStatefulWidget {
  const _FiltrosSheet();

  @override
  ConsumerState<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends ConsumerState<_FiltrosSheet> {
  final _bairroCtrl = TextEditingController();
  String? _tipo;
  double _scoreMin = 0;
  bool? _ocupado;
  bool _noRadar = false;

  static const _tipos = ['apartamento', 'casa', 'terreno', 'comercial', 'rural', 'galpao', 'outro'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () {
                ref.read(filtrosProvider.notifier).state = const FiltrosState();
                Navigator.pop(context);
              },
              child: const Text('Limpar tudo'),
            ),
          ]),
          const SizedBox(height: 16),

          TextField(
            controller: _bairroCtrl,
            decoration: const InputDecoration(labelText: 'Bairro', prefixIcon: Icon(Icons.location_on_outlined)),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _tipo,
            hint: const Text('Tipo de imóvel'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.home_outlined)),
            items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _tipo = v),
          ),
          const SizedBox(height: 12),

          Text('Score mínimo: ${_scoreMin.toInt()}'),
          Slider(
            value: _scoreMin,
            min: 0,
            max: 100,
            divisions: 10,
            label: _scoreMin.toInt().toString(),
            onChanged: (v) => setState(() => _scoreMin = v),
          ),
          const SizedBox(height: 8),

          Row(children: [
            Expanded(
              child: FilterChip(
                label: const Text('Apenas Radar'),
                selected: _noRadar,
                onSelected: (v) => setState(() => _noRadar = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilterChip(
                label: const Text('Desocupado'),
                selected: _ocupado == false,
                onSelected: (v) => setState(() => _ocupado = v ? false : null),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ref.read(filtrosProvider.notifier).state = FiltrosState(
                bairro: _bairroCtrl.text.isNotEmpty ? _bairroCtrl.text : null,
                tipo: _tipo,
                scoreMin: _scoreMin > 0 ? _scoreMin : null,
                ocupado: _ocupado,
                noRadar: _noRadar ? true : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Aplicar Filtros'),
          ),
        ],
      ),
    );
  }
}
