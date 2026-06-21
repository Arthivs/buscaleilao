from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.imovel import TipoImovelEnum, FonteEnum


class AnaliseIAOut(BaseModel):
    resumo_executivo: Optional[str] = None
    pontos_positivos: Optional[str] = None
    pontos_atencao: Optional[str] = None
    riscos_juridicos: Optional[str] = None
    recomendacao_final: Optional[str] = None
    classificacao: Optional[str] = None

    class Config:
        from_attributes = True


class ImovelBase(BaseModel):
    endereco: str
    bairro: Optional[str] = None
    cidade: str = "Aracaju"
    estado: str = "SE"
    cep: Optional[str] = None
    tipo: TipoImovelEnum
    area_construida: Optional[float] = None
    area_terreno: Optional[float] = None
    quartos: Optional[int] = None
    banheiros: Optional[int] = None
    vagas: Optional[int] = None
    ocupado: bool = False
    valor_avaliacao: float
    valor_lance_minimo: float
    valor_divida: Optional[float] = None
    data_leilao: Optional[datetime] = None
    data_segunda_praca: Optional[datetime] = None
    url_edital: Optional[str] = None
    url_imovel: Optional[str] = None
    fotos: Optional[str] = None
    numero_edital: Optional[str] = None
    numero_processo: Optional[str] = None
    matricula: Optional[str] = None
    fonte: FonteEnum = FonteEnum.outro
    leiloeiro: Optional[str] = None


class ImovelCreate(ImovelBase):
    pass


class ImovelOut(ImovelBase):
    id: int
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    score: float
    desconto_percentual: Optional[float] = None
    lucro_potencial: Optional[float] = None
    roi_estimado: Optional[float] = None
    payback_meses: Optional[int] = None
    vgv_m2: Optional[float] = None
    valor_mercado_estimado: Optional[float] = None
    no_radar: bool
    created_at: datetime
    analise_ia: Optional[AnaliseIAOut] = None
    is_favorito: Optional[bool] = False

    class Config:
        from_attributes = True


class ImovelFiltros(BaseModel):
    bairro: Optional[str] = None
    cidade: Optional[str] = None
    estado: Optional[str] = None
    tipo: Optional[TipoImovelEnum] = None
    valor_minimo: Optional[float] = None
    valor_maximo: Optional[float] = None
    area_minima: Optional[float] = None
    area_maxima: Optional[float] = None
    score_minimo: Optional[float] = None
    ocupado: Optional[bool] = None
    no_radar: Optional[bool] = None
    fonte: Optional[FonteEnum] = None
    page: int = 1
    per_page: int = 20


class ImovelListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    pages: int
    items: List[ImovelOut]
