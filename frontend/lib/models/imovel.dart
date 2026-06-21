import 'dart:convert';

class AnaliseIA {
  final String? resumoExecutivo;
  final List<String> pontosPositivos;
  final List<String> pontosAtencao;
  final List<String> riscos;
  final String? recomendacaoFinal;
  final String? classificacao;

  AnaliseIA({
    this.resumoExecutivo,
    this.pontosPositivos = const [],
    this.pontosAtencao = const [],
    this.riscos = const [],
    this.recomendacaoFinal,
    this.classificacao,
  });

  factory AnaliseIA.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.cast<String>();
      try {
        return (jsonDecode(val as String) as List).cast<String>();
      } catch (_) {
        return [];
      }
    }

    return AnaliseIA(
      resumoExecutivo: json['resumo_executivo'],
      pontosPositivos: parseList(json['pontos_positivos']),
      pontosAtencao: parseList(json['pontos_atencao']),
      riscos: parseList(json['riscos_juridicos']),
      recomendacaoFinal: json['recomendacao_final'],
      classificacao: json['classificacao'],
    );
  }
}

class Imovel {
  final int id;
  final String endereco;
  final String? bairro;
  final String cidade;
  final String estado;
  final String tipo;
  final double? areaConstuida;
  final double? areaTereno;
  final bool ocupado;
  final double valorAvaliacao;
  final double valorLance;
  final double? valorMercado;
  final double score;
  final double? desconto;
  final double? lucroPotencial;
  final double? roi;
  final int? paybackMeses;
  final DateTime? dataLeilao;
  final String? urlImovel;
  final String? urlEdital;
  final bool noRadar;
  final bool isFavorito;
  final double? latitude;
  final double? longitude;
  final AnaliseIA? analiseIA;
  final String fonte;

  Imovel({
    required this.id,
    required this.endereco,
    this.bairro,
    required this.cidade,
    required this.estado,
    required this.tipo,
    this.areaConstuida,
    this.areaTereno,
    required this.ocupado,
    required this.valorAvaliacao,
    required this.valorLance,
    this.valorMercado,
    required this.score,
    this.desconto,
    this.lucroPotencial,
    this.roi,
    this.paybackMeses,
    this.dataLeilao,
    this.urlImovel,
    this.urlEdital,
    required this.noRadar,
    required this.isFavorito,
    this.latitude,
    this.longitude,
    this.analiseIA,
    required this.fonte,
  });

  factory Imovel.fromJson(Map<String, dynamic> json) => Imovel(
        id: json['id'],
        endereco: json['endereco'] ?? '',
        bairro: json['bairro'],
        cidade: json['cidade'] ?? 'Aracaju',
        estado: json['estado'] ?? 'SE',
        tipo: json['tipo'] ?? 'outro',
        areaConstuida: (json['area_construida'] as num?)?.toDouble(),
        areaTereno: (json['area_terreno'] as num?)?.toDouble(),
        ocupado: json['ocupado'] ?? false,
        valorAvaliacao: (json['valor_avaliacao'] as num).toDouble(),
        valorLance: (json['valor_lance_minimo'] as num).toDouble(),
        valorMercado: (json['valor_mercado_estimado'] as num?)?.toDouble(),
        score: (json['score'] as num?)?.toDouble() ?? 0,
        desconto: (json['desconto_percentual'] as num?)?.toDouble(),
        lucroPotencial: (json['lucro_potencial'] as num?)?.toDouble(),
        roi: (json['roi_estimado'] as num?)?.toDouble(),
        paybackMeses: json['payback_meses'],
        dataLeilao: json['data_leilao'] != null ? DateTime.tryParse(json['data_leilao']) : null,
        urlImovel: json['url_imovel'],
        urlEdital: json['url_edital'],
        noRadar: json['no_radar'] ?? false,
        isFavorito: json['is_favorito'] ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        analiseIA: json['analise_ia'] != null ? AnaliseIA.fromJson(json['analise_ia']) : null,
        fonte: json['fonte'] ?? 'outro',
      );

  String get classificacaoLabel {
    switch (analiseIA?.classificacao) {
      case 'excelente': return 'Excelente Oportunidade';
      case 'boa': return 'Boa Oportunidade';
      case 'moderada': return 'Oportunidade Moderada';
      case 'alto_risco': return 'Alto Risco';
      default: return 'Em análise';
    }
  }
}

class ImovelListResponse {
  final int total;
  final int page;
  final int perPage;
  final int pages;
  final List<Imovel> items;

  ImovelListResponse({
    required this.total,
    required this.page,
    required this.perPage,
    required this.pages,
    required this.items,
  });

  factory ImovelListResponse.fromJson(Map<String, dynamic> json) => ImovelListResponse(
        total: json['total'],
        page: json['page'],
        perPage: json['per_page'],
        pages: json['pages'],
        items: (json['items'] as List).map((i) => Imovel.fromJson(i)).toList(),
      );
}
