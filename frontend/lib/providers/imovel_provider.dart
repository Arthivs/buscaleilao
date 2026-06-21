import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/imovel.dart';

// Filtros state
class FiltrosState {
  final String? bairro;
  final String? tipo;
  final double? valorMin;
  final double? valorMax;
  final double? scoreMin;
  final bool? ocupado;
  final bool? noRadar;
  final int page;

  const FiltrosState({
    this.bairro,
    this.tipo,
    this.valorMin,
    this.valorMax,
    this.scoreMin,
    this.ocupado,
    this.noRadar,
    this.page = 1,
  });

  FiltrosState copyWith({
    String? bairro,
    String? tipo,
    double? valorMin,
    double? valorMax,
    double? scoreMin,
    bool? ocupado,
    bool? noRadar,
    int? page,
  }) =>
      FiltrosState(
        bairro: bairro ?? this.bairro,
        tipo: tipo ?? this.tipo,
        valorMin: valorMin ?? this.valorMin,
        valorMax: valorMax ?? this.valorMax,
        scoreMin: scoreMin ?? this.scoreMin,
        ocupado: ocupado ?? this.ocupado,
        noRadar: noRadar ?? this.noRadar,
        page: page ?? this.page,
      );

  Map<String, dynamic> toQueryParams() => {
        if (bairro != null) 'bairro': bairro,
        if (tipo != null) 'tipo': tipo,
        if (valorMin != null) 'valor_minimo': valorMin,
        if (valorMax != null) 'valor_maximo': valorMax,
        if (scoreMin != null) 'score_minimo': scoreMin,
        if (ocupado != null) 'ocupado': ocupado,
        if (noRadar != null) 'no_radar': noRadar,
        'page': page,
        'per_page': 20,
      };
}

final filtrosProvider = StateProvider<FiltrosState>((ref) => const FiltrosState());

final imoveisProvider = FutureProvider.autoDispose<ImovelListResponse>((ref) async {
  final api = ref.read(apiClientProvider);
  final filtros = ref.watch(filtrosProvider);
  final resp = await api.get('/imoveis/', params: filtros.toQueryParams());
  return ImovelListResponse.fromJson(resp.data);
});

final radarProvider = FutureProvider.autoDispose<List<Imovel>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get('/imoveis/radar');
  final lista = ImovelListResponse.fromJson(resp.data);
  return lista.items;
});

final imovelDetalheProvider = FutureProvider.autoDispose.family<Imovel, int>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get('/imoveis/$id');
  return Imovel.fromJson(resp.data);
});

final dashboardResumoProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get('/dashboard/resumo');
  return Map<String, dynamic>.from(resp.data);
});

final mapaImoveisProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get('/dashboard/mapa/imoveis');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

final favoritosProvider = FutureProvider.autoDispose<List<Imovel>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get('/imoveis/favoritos/meus');
  return ImovelListResponse.fromJson(resp.data).items;
});
