"""
Motor de Score — gera pontuação de 0 a 100 para cada imóvel.

Pesos configuráveis via settings:
  - desconto       40%
  - localização    20%
  - liquidez       15%
  - valorização    15%
  - ocupação       10%
"""

from app.core.config import settings

# Bairros de Aracaju com índices de liquidez e valorização (0-100)
# Fonte: dados históricos de mercado imobiliário de Aracaju/SE
BAIRROS_ARACAJU = {
    "atalaia":         {"liquidez": 95, "valorizacao": 90},
    "coroa do meio":   {"liquidez": 90, "valorizacao": 88},
    "farolândia":      {"liquidez": 85, "valorizacao": 82},
    "jardins":         {"liquidez": 88, "valorizacao": 85},
    "grageru":         {"liquidez": 80, "valorizacao": 80},
    "luzia":           {"liquidez": 78, "valorizacao": 75},
    "13 de julho":     {"liquidez": 82, "valorizacao": 80},
    "aeroporto":       {"liquidez": 65, "valorizacao": 60},
    "centro":          {"liquidez": 70, "valorizacao": 65},
    "salgado filho":   {"liquidez": 62, "valorizacao": 58},
    "capucho":         {"liquidez": 55, "valorizacao": 50},
    "santos dumont":   {"liquidez": 60, "valorizacao": 55},
    "inácio barbosa":  {"liquidez": 58, "valorizacao": 52},
    "getúlio vargas":  {"liquidez": 50, "valorizacao": 45},
    "suíssa":          {"liquidez": 55, "valorizacao": 50},
}

DEFAULT_LIQUIDEZ = 40
DEFAULT_VALORIZACAO = 40


def _score_desconto(desconto_pct: float) -> float:
    """Desconto: 0% → 0 pts | 50%+ → 100 pts (linear)."""
    return min(desconto_pct * 2, 100)


def _score_localizacao(bairro: str | None) -> float:
    if not bairro:
        return 30
    chave = bairro.lower().strip()
    for k, v in BAIRROS_ARACAJU.items():
        if k in chave or chave in k:
            return (v["liquidez"] + v["valorizacao"]) / 2
    return 35


def _score_liquidez(bairro: str | None) -> float:
    if not bairro:
        return DEFAULT_LIQUIDEZ
    chave = bairro.lower().strip()
    for k, v in BAIRROS_ARACAJU.items():
        if k in chave or chave in k:
            return v["liquidez"]
    return DEFAULT_LIQUIDEZ


def _score_valorizacao(bairro: str | None) -> float:
    if not bairro:
        return DEFAULT_VALORIZACAO
    chave = bairro.lower().strip()
    for k, v in BAIRROS_ARACAJU.items():
        if k in chave or chave in k:
            return v["valorizacao"]
    return DEFAULT_VALORIZACAO


def _score_ocupacao(ocupado: bool) -> float:
    return 0 if ocupado else 100


def calcular_score(
    desconto_pct: float,
    bairro: str | None,
    ocupado: bool,
) -> float:
    s_desc = _score_desconto(desconto_pct)
    s_loc = _score_localizacao(bairro)
    s_liq = _score_liquidez(bairro)
    s_val = _score_valorizacao(bairro)
    s_ocu = _score_ocupacao(ocupado)

    score = (
        s_desc * settings.SCORE_PESO_DESCONTO
        + s_loc * settings.SCORE_PESO_LOCALIZACAO
        + s_liq * settings.SCORE_PESO_LIQUIDEZ
        + s_val * settings.SCORE_PESO_VALORIZACAO
        + s_ocu * settings.SCORE_PESO_OCUPACAO
    )
    return round(min(score, 100), 2)
