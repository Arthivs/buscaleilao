from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.usuario import Usuario
from app.schemas.usuario import UsuarioOut, UsuarioUpdate

router = APIRouter()


@router.get("/me", response_model=UsuarioOut)
async def meu_perfil(current_user: Usuario = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=UsuarioOut)
async def atualizar_perfil(
    dados: UsuarioUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    for field, value in dados.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    await db.commit()
    await db.refresh(current_user)
    return current_user
