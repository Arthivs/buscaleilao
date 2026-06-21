from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.models.usuario import Usuario, RoleEnum
from app.schemas.usuario import UsuarioCreate, LoginRequest, TokenResponse, UsuarioOut

router = APIRouter()


@router.post("/registrar", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def registrar(dados: UsuarioCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Usuario).where(Usuario.email == dados.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="E-mail já cadastrado")

    usuario = Usuario(
        nome=dados.nome,
        email=dados.email,
        senha_hash=hash_password(dados.senha),
        telefone=dados.telefone,
    )
    db.add(usuario)
    await db.commit()
    await db.refresh(usuario)

    token = create_access_token({"sub": str(usuario.id)})
    return TokenResponse(access_token=token, usuario=UsuarioOut.model_validate(usuario))


@router.post("/login", response_model=TokenResponse)
async def login(dados: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Usuario).where(Usuario.email == dados.email))
    usuario = result.scalar_one_or_none()

    if not usuario or not verify_password(dados.senha, usuario.senha_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-mail ou senha inválidos",
        )
    if not usuario.ativo:
        raise HTTPException(status_code=400, detail="Conta desativada")

    token = create_access_token({"sub": str(usuario.id)})
    return TokenResponse(access_token=token, usuario=UsuarioOut.model_validate(usuario))
