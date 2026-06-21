from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.alerta import CanalAlertaEnum


class AlertaCreate(BaseModel):
    bairro: Optional[str] = None
    cidade: Optional[str] = None
    estado: Optional[str] = None
    tipo_imovel: Optional[str] = None
    valor_minimo: Optional[float] = None
    valor_maximo: Optional[float] = None
    area_minima: Optional[float] = None
    score_minimo: Optional[int] = None
    desconto_minimo: Optional[float] = None
    canal: CanalAlertaEnum = CanalAlertaEnum.email


class AlertaOut(AlertaCreate):
    id: int
    usuario_id: int
    ativo: bool
    ultimo_disparo: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class SimuladorRequest(BaseModel):
    imovel_id: int
    valor_reforma: float = 0.0
    valor_impostos: float = 0.0
    outros_custos: float = 0.0
    valor_venda_esperado: Optional[float] = None


class SimuladorResponse(BaseModel):
    valor_lance: float
    valor_reforma: float
    valor_impostos: float
    outros_custos: float
    investimento_total: float
    valor_venda_esperado: float
    lucro_bruto: float
    lucro_liquido: float
    roi_percentual: float
    margem_percentual: float
    payback_meses: Optional[int] = None
