import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

final _alertasProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get('/alertas/');
  return List<dynamic>.from(resp.data);
});

class AlertasScreen extends ConsumerWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertas = ref.watch(_alertasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Alertas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _criarAlerta(context, ref),
          ),
        ],
      ),
      body: alertas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (lista) => lista.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Nenhum alerta configurado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Crie alertas para ser notificado de novas oportunidades.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Criar primeiro alerta'),
                      onPressed: () => _criarAlerta(context, ref),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                itemBuilder: (_, i) => _AlertaCard(
                  alerta: lista[i],
                  onDelete: () async {
                    final api = ref.read(apiClientProvider);
                    await api.delete('/alertas/${lista[i]['id']}');
                    ref.invalidate(_alertasProvider);
                  },
                ),
              ),
      ),
    );
  }

  void _criarAlerta(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CriarAlertaSheet(onSalvar: () => ref.invalidate(_alertasProvider)),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final Map<String, dynamic> alerta;
  final VoidCallback onDelete;

  const _AlertaCard({required this.alerta, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _canalColor(alerta['canal']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_canalIcon(alerta['canal']), color: _canalColor(alerta['canal'])),
        ),
        title: Text(_descricao(alerta), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('Canal: ${(alerta['canal'] as String).toUpperCase()}',
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: alerta['ativo'] == true ? AppTheme.secondary : AppTheme.danger,
                shape: BoxShape.circle,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remover alerta?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
                    ],
                  ),
                );
                if (ok == true) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _descricao(Map a) {
    final parts = <String>[];
    if (a['bairro'] != null) parts.add('Bairro: ${a['bairro']}');
    if (a['tipo_imovel'] != null) parts.add('Tipo: ${a['tipo_imovel']}');
    if (a['score_minimo'] != null) parts.add('Score ≥ ${a['score_minimo']}');
    if (a['desconto_minimo'] != null) parts.add('Desconto ≥ ${a['desconto_minimo']}%');
    return parts.isEmpty ? 'Todos os imóveis' : parts.join(' • ');
  }

  Color _canalColor(String? canal) {
    switch (canal) {
      case 'whatsapp': return const Color(0xFF25D366);
      case 'telegram': return const Color(0xFF0088CC);
      default: return AppTheme.primary;
    }
  }

  IconData _canalIcon(String? canal) {
    switch (canal) {
      case 'whatsapp': return Icons.chat;
      case 'telegram': return Icons.send;
      default: return Icons.email_outlined;
    }
  }
}

class _CriarAlertaSheet extends ConsumerStatefulWidget {
  final VoidCallback onSalvar;
  const _CriarAlertaSheet({required this.onSalvar});

  @override
  ConsumerState<_CriarAlertaSheet> createState() => _CriarAlertaSheetState();
}

class _CriarAlertaSheetState extends ConsumerState<_CriarAlertaSheet> {
  final _bairroCtrl = TextEditingController();
  String? _tipo;
  String _canal = 'email';
  double _scoreMin = 0;
  double _descontoMin = 0;
  bool _loading = false;

  static const _tipos = ['apartamento', 'casa', 'terreno', 'comercial', 'outro'];
  static const _canais = ['email', 'whatsapp', 'telegram'];

  Future<void> _salvar() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/alertas/', data: {
        if (_bairroCtrl.text.isNotEmpty) 'bairro': _bairroCtrl.text.trim(),
        if (_tipo != null) 'tipo_imovel': _tipo,
        if (_scoreMin > 0) 'score_minimo': _scoreMin.toInt(),
        if (_descontoMin > 0) 'desconto_minimo': _descontoMin,
        'canal': _canal,
      });
      widget.onSalvar();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Novo Alerta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          TextField(controller: _bairroCtrl,
              decoration: const InputDecoration(labelText: 'Bairro (opcional)', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _tipo,
            hint: const Text('Tipo de imóvel (opcional)'),
            items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _tipo = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.home_outlined)),
          ),
          const SizedBox(height: 12),

          Text('Score mínimo: ${_scoreMin.toInt()}'),
          Slider(value: _scoreMin, min: 0, max: 100, divisions: 10,
              onChanged: (v) => setState(() => _scoreMin = v)),

          Text('Desconto mínimo: ${_descontoMin.toInt()}%'),
          Slider(value: _descontoMin, min: 0, max: 60, divisions: 12,
              onChanged: (v) => setState(() => _descontoMin = v)),

          const SizedBox(height: 8),
          const Text('Canal de notificação:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: _canais.map((c) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.toUpperCase()),
                selected: _canal == c,
                onSelected: (_) => setState(() => _canal = c),
              ),
            ),
          )).toList()),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _salvar,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Salvar Alerta'),
          ),
        ],
      ),
    );
  }
}
