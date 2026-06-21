import enum
from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, DateTime, Boolean, String, Float, Enum as SAEnum
from sqlalchemy.orm import relationship
from app.core.database import Base


class CanalAlertaEnum(str, enum.Enum):
    email = "email"
    whatsapp = "whatsapp"
    telegram = "telegram"


class Alerta(Base):
    __tablename__ = "alertas"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)

    # Critérios do alerta
    bairro = Column(String(150), nullable=True)
    cidade = Column(String(150), nullable=True)
    estado = Column(String(2), nullable=True)
    tipo_imovel = Column(String(50), nullable=True)
    valor_minimo = Column(Float, nullable=True)
    valor_maximo = Column(Float, nullable=True)
    area_minima = Column(Float, nullable=True)
    score_minimo = Column(Integer, nullable=True)
    desconto_minimo = Column(Float, nullable=True)

    # Canal
    canal = Column(SAEnum(CanalAlertaEnum), default=CanalAlertaEnum.email)

    # Controle
    ativo = Column(Boolean, default=True)
    ultimo_disparo = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    usuario = relationship("Usuario", back_populates="alertas")
