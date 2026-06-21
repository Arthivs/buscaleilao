"""
Crawler para imóveis da Caixa Econômica Federal.
URL base: https://venda-imoveis.caixa.gov.br
"""

import re
from datetime import datetime
from typing import Optional
from loguru import logger
from app.crawlers.base_crawler import BaseCrawler, ImovelRaw

BASE_URL = "https://venda-imoveis.caixa.gov.br/sistema/busca-imovel.asp"


def _parse_valor(texto: str) -> Optional[float]:
    try:
        limpo = re.sub(r"[^\d,]", "", texto).replace(",", ".")
        return float(limpo) if limpo else None
    except Exception:
        return None


def _parse_area(texto: str) -> Optional[float]:
    try:
        match = re.search(r"([\d,\.]+)", texto.replace(",", "."))
        return float(match.group(1)) if match else None
    except Exception:
        return None


def _normalizar_tipo(descricao: str) -> str:
    d = descricao.lower()
    if "apartamento" in d or "apto" in d:
        return "apartamento"
    if "casa" in d:
        return "casa"
    if "terreno" in d or "lote" in d:
        return "terreno"
    if "comercial" in d or "loja" in d or "sala" in d:
        return "comercial"
    if "galpão" in d or "galpao" in d:
        return "galpao"
    return "outro"


class CaixaCrawler(BaseCrawler):
    NOME = "caixa"

    async def coletar(self) -> list[ImovelRaw]:
        imoveis = []

        # Navega para busca filtrada por Sergipe
        await self.page.goto(BASE_URL, wait_until="networkidle", timeout=30000)

        try:
            # Selecionar estado SE
            await self.page.select_option('select[name="UF"]', "SE")
            await self.page.wait_for_timeout(1000)

            # Selecionar cidade Aracaju quando disponível
            try:
                await self.page.select_option('select[name="cidade"]', label="ARACAJU")
                await self.page.wait_for_timeout(500)
            except Exception:
                pass

            # Submeter busca
            await self.page.click('input[type="submit"], button[type="submit"]')
            await self.page.wait_for_load_state("networkidle", timeout=30000)
        except Exception as e:
            logger.warning(f"[caixa] Erro no formulário de busca: {e}")
            return imoveis

        # Iterar páginas de resultado
        pagina = 1
        while True:
            logger.debug(f"[caixa] Processando página {pagina}")
            cards = await self.page.query_selector_all(".imovel-box, .card-imovel, tr.imovel")

            if not cards:
                break

            for card in cards:
                try:
                    imovel = await self._extrair_imovel(card)
                    if imovel:
                        imoveis.append(imovel)
                except Exception as e:
                    logger.debug(f"[caixa] Erro ao extrair card: {e}")

            # Próxima página
            proximo = await self.page.query_selector('a[rel="next"], .proxima-pagina, a:text("Próximo")')
            if not proximo:
                break
            await proximo.click()
            await self.page.wait_for_load_state("networkidle", timeout=15000)
            pagina += 1

            if pagina > 50:  # Limite de segurança
                break

        return imoveis

    async def _extrair_imovel(self, card) -> Optional[ImovelRaw]:
        texto = await card.inner_text()
        linhas = [l.strip() for l in texto.split("\n") if l.strip()]

        endereco = linhas[0] if linhas else "Não informado"
        bairro = None
        cidade = "Aracaju"
        estado = "SE"
        tipo = "outro"
        area = None
        valor_avaliacao = 0.0
        valor_lance = 0.0

        for linha in linhas:
            if "Tipo:" in linha:
                tipo = _normalizar_tipo(linha.replace("Tipo:", "").strip())
            elif "Área:" in linha or "m²" in linha:
                area = _parse_area(linha)
            elif "Avaliação:" in linha or "Valor de avaliação" in linha:
                valor_avaliacao = _parse_valor(linha) or 0
            elif "Lance" in linha or "Mínimo" in linha:
                valor_lance = _parse_valor(linha) or 0
            elif "Bairro:" in linha:
                bairro = linha.replace("Bairro:", "").strip()

        if valor_avaliacao <= 0 and valor_lance <= 0:
            return None

        url = None
        try:
            link = await card.query_selector("a")
            if link:
                url = await link.get_attribute("href")
        except Exception:
            pass

        return ImovelRaw(
            endereco=endereco,
            bairro=bairro,
            cidade=cidade,
            estado=estado,
            tipo=tipo,
            area_construida=area,
            valor_avaliacao=valor_avaliacao or valor_lance * 1.3,
            valor_lance_minimo=valor_lance or valor_avaliacao * 0.7,
            url_imovel=url,
            fonte="caixa",
        )
