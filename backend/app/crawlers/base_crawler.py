"""
Classe base para todos os crawlers.
Usa Playwright em modo headless para navegação.
"""

import hashlib
import json
from abc import ABC, abstractmethod
from datetime import datetime
from typing import Optional
from playwright.async_api import async_playwright, Browser, Page
from loguru import logger


class ImovelRaw:
    """Estrutura de dados bruta coletada pelos crawlers."""

    def __init__(self, **kwargs):
        self.endereco: str = kwargs.get("endereco", "")
        self.bairro: Optional[str] = kwargs.get("bairro")
        self.cidade: str = kwargs.get("cidade", "Aracaju")
        self.estado: str = kwargs.get("estado", "SE")
        self.cep: Optional[str] = kwargs.get("cep")
        self.tipo: str = kwargs.get("tipo", "outro")
        self.area_construida: Optional[float] = kwargs.get("area_construida")
        self.area_terreno: Optional[float] = kwargs.get("area_terreno")
        self.quartos: Optional[int] = kwargs.get("quartos")
        self.ocupado: bool = kwargs.get("ocupado", False)
        self.numero_edital: Optional[str] = kwargs.get("numero_edital")
        self.numero_processo: Optional[str] = kwargs.get("numero_processo")
        self.matricula: Optional[str] = kwargs.get("matricula")
        self.valor_avaliacao: float = kwargs.get("valor_avaliacao", 0)
        self.valor_lance_minimo: float = kwargs.get("valor_lance_minimo", 0)
        self.valor_divida: Optional[float] = kwargs.get("valor_divida")
        self.data_leilao: Optional[datetime] = kwargs.get("data_leilao")
        self.data_segunda_praca: Optional[datetime] = kwargs.get("data_segunda_praca")
        self.url_edital: Optional[str] = kwargs.get("url_edital")
        self.url_imovel: Optional[str] = kwargs.get("url_imovel")
        self.fotos: Optional[list] = kwargs.get("fotos", [])
        self.fonte: str = kwargs.get("fonte", "outro")
        self.leiloeiro: Optional[str] = kwargs.get("leiloeiro")

    def gerar_hash(self) -> str:
        """Gera hash único para deduplicação."""
        chave = f"{self.endereco}_{self.numero_processo}_{self.valor_avaliacao}_{self.fonte}"
        return hashlib.sha256(chave.encode()).hexdigest()

    def to_dict(self) -> dict:
        return {
            "endereco": self.endereco,
            "bairro": self.bairro,
            "cidade": self.cidade,
            "estado": self.estado,
            "cep": self.cep,
            "tipo": self.tipo,
            "area_construida": self.area_construida,
            "area_terreno": self.area_terreno,
            "quartos": self.quartos,
            "ocupado": self.ocupado,
            "numero_edital": self.numero_edital,
            "numero_processo": self.numero_processo,
            "matricula": self.matricula,
            "valor_avaliacao": self.valor_avaliacao,
            "valor_lance_minimo": self.valor_lance_minimo,
            "valor_divida": self.valor_divida,
            "data_leilao": self.data_leilao.isoformat() if self.data_leilao else None,
            "data_segunda_praca": self.data_segunda_praca.isoformat() if self.data_segunda_praca else None,
            "url_edital": self.url_edital,
            "url_imovel": self.url_imovel,
            "fotos": json.dumps(self.fotos or []),
            "fonte": self.fonte,
            "leiloeiro": self.leiloeiro,
            "hash_dedup": self.gerar_hash(),
        }


class BaseCrawler(ABC):
    NOME: str = "base"

    def __init__(self):
        self.browser: Optional[Browser] = None
        self.page: Optional[Page] = None

    async def __aenter__(self):
        self._playwright = await async_playwright().start()
        self.browser = await self._playwright.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-dev-shm-usage"],
        )
        self.page = await self.browser.new_page()
        await self.page.set_extra_http_headers({
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0"
        })
        return self

    async def __aexit__(self, *args):
        if self.browser:
            await self.browser.close()
        await self._playwright.stop()

    @abstractmethod
    async def coletar(self) -> list[ImovelRaw]:
        """Implementar em cada crawler específico."""
        pass

    async def executar(self) -> list[ImovelRaw]:
        try:
            logger.info(f"[{self.NOME}] Iniciando coleta...")
            resultado = await self.coletar()
            logger.info(f"[{self.NOME}] Coletados {len(resultado)} imóveis")
            return resultado
        except Exception as e:
            logger.error(f"[{self.NOME}] Erro na coleta: {e}")
            return []
