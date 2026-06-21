from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from datetime import datetime, timedelta

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.imovel import Imovel
from app.models.usuario import Usuario
from app.core.config import settings

router = APIRouter()


@router.get("/resumo")
async def resumo_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    agora = datetime.utcnow()
    proximos_30 = agora + timedelta(days=30)

    total = (await db.execute(select(func.count()).where(Imovel.ativo == True))).scalar()
    radar = (await db.execute(
        select(func.count()).where(and_(Imovel.ativo == True, Imovel.no_radar == True))
    )).scalar()
    desconto_medio = (await db.execute(
        select(func.avg(Imovel.desconto_percentual)).where(Imovel.ativo == True)
    )).scalar()
    proximos_leiloes = (await db.execute(
        select(func.count()).where(
            and_(Imovel.ativo == True, Imovel.data_leilao >= agora, Imovel.data_leilao <= proximos_30)
        )
    )).scalar()

    return {
        "total_imoveis": total,
        "oportunidades_excelentes": radar,
        "desconto_medio": round(desconto_medio or 0, 2),
        "proximos_leiloes": proximos_leiloes,
    }


@router.get("/graficos/descontos-por-bairro")
async def descontos_por_bairro(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Imovel.bairro, func.avg(Imovel.desconto_percentual).label("desconto_medio"))
        .where(and_(Imovel.ativo == True, Imovel.bairro != None))
        .group_by(Imovel.bairro)
        .order_by(func.avg(Imovel.desconto_percentual).desc())
        .limit(15)
    )
    return [{"bairro": r.bairro, "desconto_medio": round(r.desconto_medio or 0, 2)} for r in result]


@router.get("/graficos/oportunidades-por-tipo")
async def oportunidades_por_tipo(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Imovel.tipo, func.count().label("total"))
        .where(Imovel.ativo == True)
        .group_by(Imovel.tipo)
    )
    return [{"tipo": str(r.tipo), "total": r.total} for r in result]


@router.get("/graficos/roi-medio-por-bairro")
async def roi_por_bairro(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Imovel.bairro, func.avg(Imovel.roi_estimado).label("roi_medio"))
        .where(and_(Imovel.ativo == True, Imovel.roi_estimado != None, Imovel.bairro != None))
        .group_by(Imovel.bairro)
        .order_by(func.avg(Imovel.roi_estimado).desc())
        .limit(10)
    )
    return [{"bairro": r.bairro, "roi_medio": round(r.roi_medio or 0, 2)} for r in result]


@router.get("/mapa/imoveis")
async def imoveis_mapa(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    """Retorna dados leves para plotagem no mapa."""
    result = await db.execute(
        select(
            Imovel.id, Imovel.latitude, Imovel.longitude,
            Imovel.endereco, Imovel.bairro, Imovel.tipo,
            Imovel.score, Imovel.valor_lance_minimo,
            Imovel.valor_mercado_estimado, Imovel.lucro_potencial,
            Imovel.no_radar,
        ).where(
            and_(Imovel.ativo == True, Imovel.latitude != None, Imovel.longitude != None)
        )
    )
    rows = result.all()
    return [
        {
            "id": r.id, "lat": r.latitude, "lng": r.longitude,
            "endereco": r.endereco, "bairro": r.bairro, "tipo": str(r.tipo),
            "score": r.score, "valor_lance": r.valor_lance_minimo,
            "valor_mercado": r.valor_mercado_estimado,
            "lucro_potencial": r.lucro_potencial, "no_radar": r.no_radar,
        }
        for r in rows
    ]
