from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.imovel import Imovel
from app.models.usuario import Usuario
from app.schemas.alerta import SimuladorRequest, SimuladorResponse

router = APIRouter()


@router.post("/calcular", response_model=SimuladorResponse)
async def calcular_simulacao(
    dados: SimuladorRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    result = await db.execute(select(Imovel).where(Imovel.id == dados.imovel_id))
    imovel = result.scalar_one_or_none()
    if not imovel:
        raise HTTPException(status_code=404, detail="Imóvel não encontrado")

    valor_venda = dados.valor_venda_esperado or imovel.valor_mercado_estimado or imovel.valor_avaliacao
    investimento_total = (
        imovel.valor_lance_minimo
        + dados.valor_reforma
        + dados.valor_impostos
        + dados.outros_custos
    )
    lucro_bruto = valor_venda - imovel.valor_lance_minimo
    lucro_liquido = valor_venda - investimento_total
    roi = (lucro_liquido / investimento_total * 100) if investimento_total > 0 else 0
    margem = (lucro_liquido / valor_venda * 100) if valor_venda > 0 else 0

    # Payback estimado em meses (baseado em aluguel hipotético de 0.5% do valor de mercado)
    aluguel_mensal = valor_venda * 0.005
    payback = int(investimento_total / aluguel_mensal) if aluguel_mensal > 0 else None

    return SimuladorResponse(
        valor_lance=imovel.valor_lance_minimo,
        valor_reforma=dados.valor_reforma,
        valor_impostos=dados.valor_impostos,
        outros_custos=dados.outros_custos,
        investimento_total=investimento_total,
        valor_venda_esperado=valor_venda,
        lucro_bruto=round(lucro_bruto, 2),
        lucro_liquido=round(lucro_liquido, 2),
        roi_percentual=round(roi, 2),
        margem_percentual=round(margem, 2),
        payback_meses=payback,
    )
