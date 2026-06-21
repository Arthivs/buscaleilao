import enum
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean,
    DateTime, Text, Enum as SAEnum, ARRAY
)
from sqlalchemy.orm import relationship
from app.core.database import Base


class TipoImovelEnum(str, enum.Enum):
    apartamento = "apartamento"
    casa = "casa"
    terreno = "terreno"
    comercial = "comercial"
    rural = "rural"
    galpao = "galpao"
    outro = "outro"


class FonteEnum(str, enum.Enum):
    caixa = "caixa"
    banco_brasil = "banco_brasil"
    bradesco = "bradesco"
    itau = "itau"
    santander = "santander"
    tjse = "tjse"
    trf5 = "trf5"
    leiloeiro = "leiloeiro"
    outro = "outro"


class Imovel(Base):
    __tablename__ = "imoveis"

    id = Column(Integer, primary_key=True, index=True)

    # Localização
    endereco = Column(String(500), nullable=False)
    bairro = Column(String(150), index=True)
    cidade = Column(String(150), index=True, default="Aracaju")
    estado = Column(String(2), index=True, default="SE")
    cep = Column(String(9))
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    # Características
    tipo = Column(SAEnum(TipoImovelEnum), nullable=False, index=True)
    area_construida = Column(Float, nullable=True)
    area_terreno = Column(Float, nullable=True)
    quartos = Column(Integer, nullable=True)
    banheiros = Column(Integer, nullable=True)
    vagas = Column(Integer, nullable=True)
    ocupado = Column(Boolean, default=False)

    # Jurídico
    numero_edital = Column(String(100), nullable=True)
    numero_processo = Column(String(100), nullable=True, index=True)
    matricula = Column(String(100), nullable=True)
    fonte = Column(SAEnum(FonteEnum), default=FonteEnum.outro)
    leiloeiro = Column(String(200), nullable=True)

    # Valores
    valor_avaliacao = Column(Float, nullable=False)
    valor_lance_minimo = Column(Float, nullable=False)
    valor_divida = Column(Float, nullable=True)
    valor_mercado_estimado = Column(Float, nullable=True)

    # Datas
    data_leilao = Column(DateTime, nullable=True, index=True)
    data_segunda_praca = Column(DateTime, nullable=True)

    # Links e mídia
    url_edital = Column(Text, nullable=True)
    url_imovel = Column(Text, nullable=True)
    fotos = Column(Text, nullable=True)  # JSON array de URLs

    # Score e análise
    score = Column(Float, default=0.0, index=True)
    desconto_percentual = Column(Float, nullable=True)
    lucro_potencial = Column(Float, nullable=True)
    roi_estimado = Column(Float, nullable=True)
    payback_meses = Column(Integer, nullable=True)
    vgv_m2 = Column(Float, nullable=True)  # valor por m²

    # Radar
    no_radar = Column(Boolean, default=False, index=True)

    # Hash para deduplicação
    hash_dedup = Column(String(64), unique=True, index=True, nullable=True)

    # Controle
    ativo = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relacionamentos
    favoritos = relationship("Favorito", back_populates="imovel", cascade="all, delete-orphan")
    analise_ia = relationship("AnaliseIA", back_populates="imovel", uselist=False, cascade="all, delete-orphan")
