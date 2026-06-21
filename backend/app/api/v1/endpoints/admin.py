from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.core.database import get_db
from app.api.deps import get_current_admin
from app.models.usuario import Usuario
from app.models.imovel import Imovel
from app.schemas.usuario import UsuarioOut, UsuarioAdminUpdate

router = APIRouter()


@router.get("/usuarios", response_model=list[UsuarioOut])
async def listar_usuarios(
    db: AsyncSession = Depends(get_db),
    _: Usuario = Depends(get_current_admin),
):
    result = await db.execute(select(Usuario).order_by(Usuario.created_at.desc()))
    return result.scalars().all()


@router.put("/usuarios/{usuario_id}", response_model=UsuarioOut)
async def atualizar_usuario(
    usuario_id: int,
    dados: UsuarioAdminUpdate,
    db: AsyncSession = Depends(get_db),
    _: Usuario = Depends(get_current_admin),
):
    result = await db.execute(select(Usuario).where(Usuario.id == usuario_id))
    usuario = result.scalar_one_or_none()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    for field, value in dados.model_dump(exclude_none=True).items():
        setattr(usuario, field, value)
    await db.commit()
    await db.refresh(usuario)
    return usuario


@router.post("/coletar")
async def disparar_coleta(
    background_tasks: BackgroundTasks,
    fonte: str = "all",
    _: Usuario = Depends(get_current_admin),
):
    """Dispara manualmente a coleta de dados dos crawlers."""
    from app.tasks.coleta_task import executar_coleta_completa
    background_tasks.add_task(executar_coleta_completa, fonte)
    return {"message": f"Coleta iniciada para fonte: {fonte}"}


@router.get("/stats")
async def estatisticas_sistema(
    db: AsyncSession = Depends(get_db),
    _: Usuario = Depends(get_current_admin),
):
    total_usuarios = (await db.execute(select(func.count()).select_from(Usuario))).scalar()
    total_imoveis = (await db.execute(select(func.count()).select_from(Imovel))).scalar()
    imoveis_radar = (await db.execute(
        select(func.count()).where(Imovel.no_radar == True)
    )).scalar()
    return {
        "total_usuarios": total_usuarios,
        "total_imoveis": total_imoveis,
        "imoveis_no_radar": imoveis_radar,
    }
