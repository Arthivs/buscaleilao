import enum
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SAEnum
from sqlalchemy.orm import relationship
from app.core.database import Base


class PlanoEnum(str, enum.Enum):
    free = "free"
    pro = "pro"
    enterprise = "enterprise"


class RoleEnum(str, enum.Enum):
    admin = "admin"
    investidor = "investidor"


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(150), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    senha_hash = Column(String(255), nullable=False)
    role = Column(SAEnum(RoleEnum), default=RoleEnum.investidor, nullable=False)
    plano = Column(SAEnum(PlanoEnum), default=PlanoEnum.free, nullable=False)
    ativo = Column(Boolean, default=True)
    telefone = Column(String(20), nullable=True)
    telegram_chat_id = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    favoritos = relationship("Favorito", back_populates="usuario", cascade="all, delete-orphan")
    alertas = relationship("Alerta", back_populates="usuario", cascade="all, delete-orphan")
