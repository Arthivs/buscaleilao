from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


class Favorito(Base):
    __tablename__ = "favoritos"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    imovel_id = Column(Integer, ForeignKey("imoveis.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    usuario = relationship("Usuario", back_populates="favoritos")
    imovel = relationship("Imovel", back_populates="favoritos")
