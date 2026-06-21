"""Testes do motor de score."""

import pytest
from app.services.score_service import calcular_score, _score_desconto, _score_ocupacao


def test_score_desconto_zero():
    assert _score_desconto(0) == 0


def test_score_desconto_50():
    assert _score_desconto(50) == 100


def test_score_desconto_linear():
    assert _score_desconto(25) == 50


def test_score_ocupacao_desocupado():
    assert _score_ocupacao(False) == 100


def test_score_ocupacao_ocupado():
    assert _score_ocupacao(True) == 0


def test_calcular_score_excelente():
    """Imóvel em Atalaia com 50% de desconto e desocupado deve ter score alto."""
    score = calcular_score(50.0, "Atalaia", False)
    assert score >= 80


def test_calcular_score_ruim():
    """Imóvel ocupado sem desconto deve ter score baixo."""
    score = calcular_score(0.0, "Centro", True)
    assert score < 30


def test_calcular_score_limites():
    """Score deve sempre estar entre 0 e 100."""
    for desconto in [0, 10, 30, 50, 70]:
        score = calcular_score(desconto, "Jardins", False)
        assert 0 <= score <= 100
