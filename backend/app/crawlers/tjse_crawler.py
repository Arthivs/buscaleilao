"""
Crawler para leilões judiciais do TJSE (Tribunal de Justiça de Sergipe).
URL: https://www.tjse.jus.br/portal/leiloes
"""

import re
from datetime import datetime
from typing import Optional
from loguru import logger
from app.crawlers.base_crawler import BaseCrawler, ImovelRaw

BASE_URL = "https://www.tjse.jus.br/portal/leiloes"


def _parse_data(texto: str) -> Optional[datetime]:
    formatos = ["%d/%m/%Y %H:%M", "%d/%m/%Y", "%Y-%m-%d"]
    for fmt in formatos:
        try:
            return datetime.strptime(texto.strip(), fmt)
        except Exception:
            pass
    return None


class TJSECrawler(BaseCrawler):
    NOME = "tjse"

    async def coletar(self) -> list[ImovelRaw]:
        imoveis = []

        try:
            await self.page.goto(BASE_URL, wait_until="networkidle", timeout=30000)
        except Exception as e:
            logger.warning(f"[tjse] Não foi possível acessar TJSE: {e}")
            return imoveis

        # Filtrar por imóveis em Aracaju
        try:
            await self.page.fill('input[placeholder*="cidade"], input[name*="cidade"]', "Aracaju")
            await self.page.keyboard.press("Enter")
            await self.page.wait_for_load_state("networkidle", timeout=15000)
        except Exception:
            pass

        cards = await self.page.query_selector_all(".leilao-item, .processo-item, tr.leilao")
        logger.info(f"[tjse] Encontrados {len(cards)} registros")

        for card in cards:
            try:
                imovel = await self._extrair_imovel(card)
                if imovel:
                    imoveis.append(imovel)
            except Exception as e:
                logger.debug(f"[tjse] Erro ao extrair item: {e}")

        return imoveis

    async def _extrair_imovel(self, card) -> Optional[ImovelRaw]:
        texto = await card.inner_text()
        linhas = [l.strip() for l in texto.split("\n") if l.strip()]

        numero_processo = None
        endereco = "Não informado"
        valor_avaliacao = 0.0
        valor_lance = 0.0
        data_leilao = None

        for linha in linhas:
            if re.match(r"\d{7}-\d{2}\.\d{4}\.\d\.\d{2}\.\d{4}", linha):
                numero_processo = linha
            elif any(w in linha.lower() for w in ["rua", "avenida", "av.", "praça", "travessa"]):
                endereco = linha
            elif "avaliação" in linha.lower():
                m = re.search(r"R\$\s*([\d.,]+)", linha)
                if m:
                    valor_avaliacao = float(m.group(1).replace(".", "").replace(",", "."))
            elif "lance" in linha.lower() or "mínimo" in linha.lower():
                m = re.search(r"R\$\s*([\d.,]+)", linha)
                if m:
                    valor_lance = float(m.group(1).replace(".", "").replace(",", "."))
            elif re.search(r"\d{2}/\d{2}/\d{4}", linha):
                data_leilao = _parse_data(linha)

        if valor_avaliacao <= 0:
            return None

        return ImovelRaw(
            endereco=endereco,
            cidade="Aracaju",
            estado="SE",
            tipo="outro",
            valor_avaliacao=valor_avaliacao,
            valor_lance_minimo=valor_lance or valor_avaliacao * 0.6,
            numero_processo=numero_processo,
            data_leilao=data_leilao,
            fonte="tjse",
        )
