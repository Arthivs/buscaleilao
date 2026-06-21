import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../providers/imovel_provider.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class SimuladorScreen extends ConsumerStatefulWidget {
  final int? imovelId;
  const SimuladorScreen({super.key, this.imovelId});

  @override
  ConsumerState<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends ConsumerState<SimuladorScreen> {
  final _reformaCtrl = TextEditingController(text: '0');
  final _impostosCtrl = TextEditingController(text: '0');
  final _outrosCtrl = TextEditingController(text: '0');
  final _vendaCtrl = TextEditingController();
  Map<String, dynamic>? _resultado;
  bool _loading = false;

  double _parseValor(String v) =>
      double.tryParse(v.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _calcular() async {
    if (widget.imovelId == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = {
        'imovel_id': widget.imovelId,
        'valor_reforma': _parseValor(_reformaCtrl.text),
        'valor_impostos': _parseValor(_impostosCtrl.text),
        'outros_custos': _parseValor(_outrosCtrl.text),
        if (_vendaCtrl.text.isNotEmpty) 'valor_venda_esperado': _parseValor(_vendaCtrl.text),
      };
      final resp = await api.post('/simulador/calcular', data: body);
      setState(() => _resultado = Map<String, dynamic>.from(resp.data));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imovel = widget.imovelId != null
        ? ref.watch(imovelDetalheProvider(widget.imovelId!))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Simulador de Investimento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info do imóvel
            if (imovel != null)
              imovel.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
                data: (im) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Imóvel selecionado',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(im.endereco, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          _ValorChip('Lance', _brl.format(im.valorLance), AppTheme.primary),
                          const SizedBox(width: 8),
                          if (im.valorMercado != null)
                            _ValorChip('Mercado', _brl.format(im.valorMercado), AppTheme.secondary),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Text('Custos adicionais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            _Campo('Reforma estimada (R\$)', _reformaCtrl),
            const SizedBox(height: 12),
            _Campo('Impostos e taxas (R\$)', _impostosCtrl),
            const SizedBox(height: 12),
            _Campo('Outros custos (R\$)', _outrosCtrl),
            const SizedBox(height: 12),
            _Campo('Valor de venda esperado (R\$) — opcional', _vendaCtrl),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate),
              label: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Calcular Retorno'),
              onPressed: widget.imovelId == null || _loading ? null : _calcular,
            ),

            if (_resultado != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Resultado da Simulação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _ResultRow('Investimento Total', _brl.format(_resultado!['investimento_total']), bold: true),
                    _ResultRow('Valor de Venda', _brl.format(_resultado!['valor_venda_esperado'])),
                    const Divider(),
                    _ResultRow('Lucro Bruto', _brl.format(_resultado!['lucro_bruto']), color: AppTheme.secondary),
                    _ResultRow('Lucro Líquido', _brl.format(_resultado!['lucro_liquido']), color: AppTheme.secondary, bold: true),
                    _ResultRow('ROI', '${(_resultado!['roi_percentual'] as num).toStringAsFixed(2)}%', color: AppTheme.secondary, bold: true),
                    _ResultRow('Margem', '${(_resultado!['margem_percentual'] as num).toStringAsFixed(2)}%'),
                    if (_resultado!['payback_meses'] != null)
                      _ResultRow('Payback', '${_resultado!['payback_meses']} meses'),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Esta simulação é estimativa. Considere custos com cartório, advogado, ITBI e eventuais reformas não planejadas.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _Campo(this.label, this.ctrl);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
      ),
    );
  }
}

class _ValorChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ValorChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _ResultRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppTheme.text,
            fontSize: bold ? 16 : 14,
          )),
        ],
      ),
    );
  }
}
