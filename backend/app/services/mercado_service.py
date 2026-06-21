"""
Serviço de estimativa de valor de mercado.

Estratégia: usa tabela de VGV/m² por bairro e tipo de imóvel.
Preparado para substituição futura por API imobiliária (VivaReal, ZAP, OLX).
"""

from app.models.imovel import TipoImovelEnum

# VGV por m² em Aracaju (R$/m²) – dados de referência de mercado 2024
VGV_BAIRRO_TIPO: dict[str, dict[str, float]] = {
    "atalaia": {
        "apartamento": 7500, "casa": 5500, "terreno": 3000,
        "comercial": 8000, "outro": 5000,
    },
    "coroa do meio": {
        "apartamento": 7000, "casa": 5000, "terreno": 2800,
        "comercial": 7500, "outro": 4800,
    },
    "farolândia": {
        "apartamento": 6500, "casa": 4800, "terreno": 2500,
        "comercial": 7000, "outro": 4500,
    },
    "jardins": {
        "apartamento": 6800, "casa": 5200, "terreno": 2700,
        "comercial": 7200, "outro": 4700,
    },
    "grageru": {
        "apartamento": 6200, "casa": 4600, "terreno": 2400,
        "comercial": 6800, "outro": 4400,
    },
    "centro": {
        "apartamento": 4500, "casa": 3500, "terreno": 2000,
        "comercial": 5500, "outro": 3500,
    },
}

DEFAULT_VGV: dict[str, float] = {
    "apartamento": 4000, "casa": 3000, "terreno": 1500,
    "comercial": 5000, "rural": 800, "galpao": 2500, "outro": 3000,
}


def estimar_valor_mercado(
    bairro: str | None,
    tipo: TipoImovelEnum,
    area: float | None,
) -> tuple[float | None, float | None]:
    """
    Retorna (valor_mercado_estimado, vgv_por_m2).
    Se não há área, retorna (None, vgv_por_m2).
    """
    tipo_str = str(tipo).replace("TipoImovelEnum.", "").lower()

    vgv = DEFAULT_VGV.get(tipo_str, 3000)
    if bairro:
        chave = bairro.lower().strip()
        for k, tipos in VGV_BAIRRO_TIPO.items():
            if k in chave or chave in k:
                vgv = tipos.get(tipo_str, vgv)
                break

    area_ref = area or 0
    if area_ref <= 0:
        return None, vgv

    return round(area_ref * vgv, 2), vgv


def calcular_metricas(
    valor_lance: float,
    valor_mercado: float | None,
) -> dict:
    if not valor_mercado or valor_mercado <= 0:
        return {"desconto_percentual": None, "lucro_potencial": None, "roi_estimado": None}

    desconto = ((valor_mercado - valor_lance) / valor_mercado) * 100
    lucro = valor_mercado - valor_lance
    roi = (lucro / valor_lance) * 100 if valor_lance > 0 else 0

    return {
        "desconto_percentual": round(desconto, 2),
        "lucro_potencial": round(lucro, 2),
        "roi_estimado": round(roi, 2),
    }
