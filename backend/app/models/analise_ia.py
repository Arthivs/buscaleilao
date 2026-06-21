from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, DateTime, Text, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class AnaliseIA(Base):
    __tablename__ = "analises_ia"

    id = Column(Integer, primary_key=True, index=True)
    imovel_id = Column(Integer, ForeignKey("imoveis.id"), unique=True, nullable=False)

    resumo_executivo = Column(Text, nullable=True)
    pontos_positivos = Column(Text, nullable=True)   # JSON array
    pontos_atencao = Column(Text, nullable=True)     # JSON array
    riscos_juridicos = Column(Text, nullable=True)   # JSON array
    recomendacao_final = Column(Text, nullable=True)
    classificacao = Column(String(50), nullable=True)  # excelente / boa / moderada / alto_risco

    modelo_usado = Column(String(50), nullable=True)
    tokens_usados = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    imovel = relationship("Imovel", back_populates="analise_ia")
