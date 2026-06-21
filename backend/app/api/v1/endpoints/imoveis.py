from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import selectinload
from typing import Optional
import math

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.imovel import Imovel, TipoImovelEnum, FonteEnum
from app.models.favorito import Favorito
from app.models.usuario import Usuario
from app.schemas.imovel import ImovelOut, ImovelListResponse, ImovelFiltros

router = APIRouter()


def build_filtros(query, filtros: ImovelFiltros):
    conditions = [Imovel.ativo == True]
    if filtros.bairro:
        conditions.append(Imovel.bairro.ilike(f"%{filtros.bairro}%"))
    if filtros.cidade:
        conditions.append(Imovel.cidade.ilike(f"%{filtros.cidade}%"))
    if filtros.estado:
        conditions.append(Imovel.estado == filtros.estado.upper())
    if filtros.tipo:
        conditions.append(Imovel.tipo == filtros.tipo)
    if filtros.valor_minimo is not None:
        conditions.append(Imovel.valor_lance_minimo >= filtros.valor_minimo)
    if filtros.valor_maximo is not None:
        conditions.append(Imovel.valor_lance_minimo <= filtros.valor_maximo)
    if filtros.area_minima is not None:
        conditions.append(Imovel.area_construida >= filtros.area_minima)
    if filtros.area_maxima is not None:
        conditions.append(Imovel.area_construida <= filtros.area_maxima)
    if filtros.score_minimo is not None:
        conditions.append(Imovel.score >= filtros.score_minimo)
    if filtros.ocupado is not None:
        conditions.append(Imovel.ocupado == filtros.ocupado)
    if filtros.no_radar is not None:
        conditions.append(Imovel.no_radar == filtros.no_radar)
    if filtros.fonte:
        conditions.append(Imovel.fonte == filtros.fonte)
    return query.where(and_(*conditions))


@router.get("/", response_model=ImovelListResponse)
async def listar_imoveis(
    bairro: Optional[str] = None,
    cidade: Optional[str] = None,
    estado: Optional[str] = None,
    tipo: Optional[TipoImovelEnum] = None,
    valor_minimo: Optional[float] = None,
    valor_maximo: Optional[float] = None,
    area_minima: Optional[float] = None,
    area_maxima: Optional[float] = None,
    score_minimo: Optional[float] = None,
    ocupado: Optional[bool] = None,
    no_radar: Optional[bool] = None,
    fonte: Optional[FonteEnum] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    filtros = ImovelFiltros(
        bairro=bairro, cidade=cidade, estado=estado, tipo=tipo,
        valor_minimo=valor_minimo, valor_maximo=valor_maximo,
        area_minima=area_minima, area_maxima=area_maxima,
        score_minimo=score_minimo, ocupado=ocupado, no_radar=no_radar,
        fonte=fonte, page=page, per_page=per_page,
    )

    base_query = select(Imovel).options(selectinload(Imovel.analise_ia))
    base_query = build_filtros(base_query, filtros)

    count_query = select(func.count()).select_from(base_query.subquery())
    total = (await db.execute(count_query)).scalar()

    offset = (page - 1) * per_page
    result = await db.execute(
        base_query.order_by(Imovel.score.desc()).offset(offset).limit(per_page)
    )
    imoveis = result.scalars().all()

    # Marcar favoritos
    fav_result = await db.execute(
        select(Favorito.imovel_id).where(Favorito.usuario_id == current_user.id)
    )
    favoritos_ids = set(fav_result.scalars().all())

    items = []
    for im in imoveis:
        out = ImovelOut.model_validate(im)
        out.is_favorito = im.id in favoritos_ids
        items.append(out)

    return ImovelListResponse(
        total=total,
        page=page,
        per_page=per_page,
        pages=math.ceil(total / per_page),
        items=items,
    )


@router.get("/radar", response_model=ImovelListResponse)
async def radar_oportunidades(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    """Retorna apenas imóveis que atendem simultaneamente todos os critérios do Radar."""
    from datetime import datetime, timedelta
    from app.core.config import settings

    prazo = datetime.utcnow() + timedelta(days=settings.RADAR_DIAS_LEILAO)
    query = (
        select(Imovel)
        .options(selectinload(Imovel.analise_ia))
        .where(
            and_(
                Imovel.ativo == True,
                Imovel.score >= settings.RADAR_SCORE_MINIMO,
                Imovel.desconto_percentual >= settings.RADAR_DESCONTO_MINIMO,
                Imovel.lucro_potencial >= settings.RADAR_LUCRO_MINIMO,
                Imovel.data_leilao <= prazo,
                Imovel.data_leilao >= datetime.utcnow(),
            )
        )
        .order_by(Imovel.score.desc())
    )
    result = await db.execute(query)
    imoveis = result.scalars().all()

    fav_result = await db.execute(
        select(Favorito.imovel_id).where(Favorito.usuario_id == current_user.id)
    )
    favoritos_ids = set(fav_result.scalars().all())

    items = []
    for im in imoveis:
        out = ImovelOut.model_validate(im)
        out.is_favorito = im.id in favoritos_ids
        items.append(out)

    return ImovelListResponse(total=len(items), page=1, per_page=len(items) or 1, pages=1, items=items)


@router.get("/{imovel_id}", response_model=ImovelOut)
async def detalhe_imovel(
    imovel_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Imovel).options(selectinload(Imovel.analise_ia)).where(Imovel.id == imovel_id)
    )
    imovel = result.scalar_one_or_none()
    if not imovel:
        raise HTTPException(status_code=404, detail="Imóvel não encontrado")

    fav_result = await db.execute(
        select(Favorito).where(
            and_(Favorito.usuario_id == current_user.id, Favorito.imovel_id == imovel_id)
        )
    )
    out = ImovelOut.model_validate(imovel)
    out.is_favorito = fav_result.scalar_one_or_none() is not None
    return out


@router.post("/{imovel_id}/favoritar")
async def favoritar(
    imovel_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Favorito).where(
            and_(Favorito.usuario_id == current_user.id, Favorito.imovel_id == imovel_id)
        )
    )
    fav = result.scalar_one_or_none()
    if fav:
        await db.delete(fav)
        await db.commit()
        return {"favorito": False}

    db.add(Favorito(usuario_id=current_user.id, imovel_id=imovel_id))
    await db.commit()
    return {"favorito": True}


@router.get("/favoritos/meus", response_model=ImovelListResponse)
async def meus_favoritos(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Imovel)
        .options(selectinload(Imovel.analise_ia))
        .join(Favorito, Favorito.imovel_id == Imovel.id)
        .where(Favorito.usuario_id == current_user.id)
        .order_by(Imovel.score.desc())
    )
    imoveis = result.scalars().all()
    items = [ImovelOut.model_validate(im) for im in imoveis]
    for i in items:
        i.is_favorito = True
    return ImovelListResponse(total=len(items), page=1, per_page=len(items) or 1, pages=1, items=items)
