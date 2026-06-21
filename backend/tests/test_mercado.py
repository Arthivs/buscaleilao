"""Testes do serviço de estimativa de mercado."""

import pytest
from app.services.mercado_service import estimar_valor_mercado, calcular_metricas
from app.models.imovel import TipoImovelEnum


def test_estimar_apartamento_atalaia():
    valor, vgv = estimar_valor_mercado("Atalaia", TipoImovelEnum.apartamento, 75)
    assert valor == 75 * 7500
    assert vgv == 7500


def test_estimar_sem_area():
    valor, vgv = estimar_valor_mercado("Centro", TipoImovelEnum.casa, None)
    assert valor is None
    assert vgv > 0


def test_estimar_bairro_desconhecido():
    valor, vgv = estimar_valor_mercado("Bairro Desconhecido", TipoImovelEnum.apartamento, 60)
    # Deve usar valor default
    assert valor > 0
    assert vgv == 4000


def test_calcular_metricas_desconto():
    metricas = calcular_metricas(300_000, 500_000)
    assert metricas["desconto_percentual"] == 40.0
    assert metricas["lucro_potencial"] == 200_000
    assert metricas["roi_estimado"] > 0


def test_calcular_metricas_sem_mercado():
    metricas = calcular_metricas(300_000, None)
    assert metricas["desconto_percentual"] is None
