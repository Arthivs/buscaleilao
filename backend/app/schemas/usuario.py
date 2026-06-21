from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from app.models.usuario import PlanoEnum, RoleEnum


class UsuarioBase(BaseModel):
    nome: str
    email: EmailStr
    telefone: Optional[str] = None


class UsuarioCreate(UsuarioBase):
    senha: str


class UsuarioUpdate(BaseModel):
    nome: Optional[str] = None
    telefone: Optional[str] = None
    telegram_chat_id: Optional[str] = None


class UsuarioAdminUpdate(UsuarioUpdate):
    plano: Optional[PlanoEnum] = None
    role: Optional[RoleEnum] = None
    ativo: Optional[bool] = None


class UsuarioOut(UsuarioBase):
    id: int
    role: RoleEnum
    plano: PlanoEnum
    ativo: bool
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioOut


class LoginRequest(BaseModel):
    email: EmailStr
    senha: str
