"""
Tasks Celery para coleta e processamento de imóveis.
"""

import asyncio
from loguru import logger
from sqlalchemy import select
from app.tasks.celery_app import celery_app
from app.core.database import AsyncSessionLocal
from app.models.imovel import Imovel
from app.models.analise_ia import AnaliseIA
from app.services.mercado_service import estimar_valor_mercado, calcular_metricas
from app.services.score_service import calcular_score
from app.services.ia_service import gerar_analise_ia
from app.core.config import settings


async def _geocodificar(endereco: str, cidade: str, estado: str) -> tuple[float | None, float | None]:
    """Geocodifica endereço usando Nominatim (OpenStreetMap)."""
    try:
        import httpx
        query = f"{endereco}, {cidade}, {estado}, Brasil"
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": query, "format": "json", "limit": 1},
                headers={"User-Agent": "LeilaoInteligente/1.0"},
                timeout=10,
            )
            data = resp.json()
            if data:
                return float(data[0]["lat"]), float(data[0]["lon"])
    except Exception as e:
        logger.debug(f"Geocoding error: {e}")
    return None, None


async def _processar_imovel(raw_dict: dict, db) -> bool:
    """Salva ou atualiza um imóvel, calcula métricas e score."""
    from app.models.imovel import TipoImovelEnum, FonteEnum

    hash_dedup = raw_dict.get("hash_dedup")
    if hash_dedup:
        result = await db.execute(select(Imovel).where(Imovel.hash_dedup == hash_dedup))
        if result.scalar_one_or_none():
            return False  # Duplicado

    # Estimar valor de mercado
    tipo_str = raw_dict.get("tipo", "outro")
    try:
        tipo_enum = TipoImovelEnum(tipo_str)
    except ValueError:
        tipo_enum = TipoImovelEnum.outro

    valor_mercado, vgv_m2 = estimar_valor_mercado(
        raw_dict.get("bairro"),
        tipo_enum,
        raw_dict.get("area_construida"),
    )
    metricas = calcular_metricas(raw_dict.get("valor_lance_minimo", 0), valor_mercado)
    score = calcular_score(
        metricas.get("desconto_percentual") or 0,
        raw_dict.get("bairro"),
        raw_dict.get("ocupado", False),
    )

    # Radar
    no_radar = (
        score >= settings.RADAR_SCORE_MINIMO
        and (metricas.get("desconto_percentual") or 0) >= settings.RADAR_DESCONTO_MINIMO
        and (metricas.get("lucro_potencial") or 0) >= settings.RADAR_LUCRO_MINIMO
    )

    # Geocodificação
    lat, lng = await _geocodificar(
        raw_dict.get("endereco", ""),
        raw_dict.get("cidade", "Aracaju"),
        raw_dict.get("estado", "SE"),
    )

    imovel = Imovel(
        endereco=raw_dict.get("endereco", ""),
        bairro=raw_dict.get("bairro"),
        cidade=raw_dict.get("cidade", "Aracaju"),
        estado=raw_dict.get("estado", "SE"),
        cep=raw_dict.get("cep"),
        latitude=lat,
        longitude=lng,
        tipo=tipo_enum,
        area_construida=raw_dict.get("area_construida"),
        area_terreno=raw_dict.get("area_terreno"),
        quartos=raw_dict.get("quartos"),
        ocupado=raw_dict.get("ocupado", False),
        numero_edital=raw_dict.get("numero_edital"),
        numero_processo=raw_dict.get("numero_processo"),
        matricula=raw_dict.get("matricula"),
        fonte=raw_dict.get("fonte", "outro"),
        leiloeiro=raw_dict.get("leiloeiro"),
        valor_avaliacao=raw_dict.get("valor_avaliacao", 0),
        valor_lance_minimo=raw_dict.get("valor_lance_minimo", 0),
        valor_divida=raw_dict.get("valor_divida"),
        valor_mercado_estimado=valor_mercado,
        data_leilao=raw_dict.get("data_leilao"),
        data_segunda_praca=raw_dict.get("data_segunda_praca"),
        url_edital=raw_dict.get("url_edital"),
        url_imovel=raw_dict.get("url_imovel"),
        fotos=raw_dict.get("fotos"),
        score=score,
        desconto_percentual=metricas.get("desconto_percentual"),
        lucro_potencial=metricas.get("lucro_potencial"),
        roi_estimado=metricas.get("roi_estimado"),
        vgv_m2=vgv_m2,
        no_radar=no_radar,
        hash_dedup=hash_dedup,
    )
    db.add(imovel)
    await db.flush()

    # Análise IA
    try:
        analise_data = await gerar_analise_ia({
            **raw_dict,
            "score": score,
            "desconto_percentual": metricas.get("desconto_percentual"),
            "lucro_potencial": metricas.get("lucro_potencial"),
            "roi_estimado": metricas.get("roi_estimado"),
            "valor_mercado_estimado": valor_mercado,
        })
        analise = AnaliseIA(imovel_id=imovel.id, **analise_data)
        db.add(analise)
    except Exception as e:
        logger.warning(f"Análise IA falhou para imóvel {imovel.id}: {e}")

    await db.commit()
    return True


async def _run_crawlers(fonte: str) -> list[dict]:
    from app.crawlers.caixa_crawler import CaixaCrawler
    from app.crawlers.tjse_crawler import TJSECrawler

    crawlers = []
    if fonte in ("all", "caixa"):
        crawlers.append(CaixaCrawler)
    if fonte in ("all", "tjse"):
        crawlers.append(TJSECrawler)

    todos = []
    for CrawlerClass in crawlers:
        async with CrawlerClass() as crawler:
            items = await crawler.executar()
            todos.extend([i.to_dict() for i in items])
    return todos


@celery_app.task(name="app.tasks.coleta_task.executar_coleta_completa", bind=True, max_retries=3)
def executar_coleta_completa(self, fonte: str = "all"):
    async def _run():
        logger.info(f"Iniciando coleta completa — fonte: {fonte}")
        raw_items = await _run_crawlers(fonte)
        logger.info(f"Total coletado bruto: {len(raw_items)}")

        novos = 0
        async with AsyncSessionLocal() as db:
            for item in raw_items:
                try:
                    if await _processar_imovel(item, db):
                        novos += 1
                except Exception as e:
                    logger.error(f"Erro ao processar imóvel: {e}")
                    await db.rollback()

        logger.info(f"Coleta finalizada. Novos imóveis: {novos}/{len(raw_items)}")
        return {"coletados": len(raw_items), "novos": novos}

    return asyncio.get_event_loop().run_until_complete(_run())


@celery_app.task(name="app.tasks.coleta_task.recalcular_todos_scores")
def recalcular_todos_scores():
    async def _run():
        from sqlalchemy import update
        logger.info("Recalculando scores de todos os imóveis ativos...")
        async with AsyncSessionLocal() as db:
            result = await db.execute(select(Imovel).where(Imovel.ativo == True))
            imoveis = result.scalars().all()
            atualizados = 0
            for imovel in imoveis:
                novo_score = calcular_score(
                    imovel.desconto_percentual or 0,
                    imovel.bairro,
                    imovel.ocupado,
                )
                no_radar = (
                    novo_score >= settings.RADAR_SCORE_MINIMO
                    and (imovel.desconto_percentual or 0) >= settings.RADAR_DESCONTO_MINIMO
                    and (imovel.lucro_potencial or 0) >= settings.RADAR_LUCRO_MINIMO
                )
                imovel.score = novo_score
                imovel.no_radar = no_radar
                atualizados += 1
            await db.commit()
        logger.info(f"Scores recalculados: {atualizados}")

    asyncio.get_event_loop().run_until_complete(_run())
