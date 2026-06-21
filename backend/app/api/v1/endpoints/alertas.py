from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.alerta import Alerta
from app.models.usuario import Usuario, PlanoEnum
from app.schemas.alerta import AlertaCreate, AlertaOut
from app.core.config import settings

router = APIRouter()

PLANO_LIMITES = {
    PlanoEnum.free: settings.PLAN_FREE_MAX_ALERTS,
    PlanoEnum.pro: settings.PLAN_PRO_MAX_ALERTS,
    PlanoEnum.enterprise: settings.PLAN_ENTERPRISE_MAX_ALERTS,
}


@router.get("/", response_model=list[AlertaOut])
async def listar_alertas(
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Alerta).where(Alerta.usuario_id == current_user.id).order_by(Alerta.created_at.desc())
    )
    return result.scalars().all()


@router.post("/", response_model=AlertaOut, status_code=201)
async def criar_alerta(
    dados: AlertaCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    limite = PLANO_LIMITES.get(current_user.plano, 3)
    count_result = await db.execute(
        select(Alerta).where(Alerta.usuario_id == current_user.id, Alerta.ativo == True)
    )
    ativos = len(count_result.scalars().all())
    if ativos >= limite:
        raise HTTPException(
            status_code=403,
            detail=f"Limite de {limite} alertas atingido para o plano {current_user.plano}. Faça upgrade.",
        )

    alerta = Alerta(usuario_id=current_user.id, **dados.model_dump())
    db.add(alerta)
    await db.commit()
    await db.refresh(alerta)
    return alerta


@router.delete("/{alerta_id}")
async def remover_alerta(
    alerta_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(
        select(Alerta).where(Alerta.id == alerta_id, Alerta.usuario_id == current_user.id)
    )
    alerta = result.scalar_one_or_none()
    if not alerta:
        raise HTTPException(status_code=404, detail="Alerta não encontrado")
    await db.delete(alerta)
    await db.commit()
    return {"ok": True}
