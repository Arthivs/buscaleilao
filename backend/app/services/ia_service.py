"""
Serviço de análise com IA (OpenAI GPT-4o-mini).
Gera análise completa do imóvel em formato estruturado.
"""

import json
from openai import AsyncOpenAI
from app.core.config import settings
from loguru import logger


client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

CLASSIFICACOES = ["excelente", "boa", "moderada", "alto_risco"]

PROMPT_SISTEMA = """Você é um especialista em análise de imóveis em leilão no Brasil,
com foco no mercado de Aracaju/SE. Analise o imóvel fornecido e retorne um JSON estruturado
com a análise completa. Seja objetivo, realista e use linguagem profissional para investidores."""

PROMPT_ANALISE = """
Analise este imóvel em leilão e retorne APENAS um JSON válido com esta estrutura exata:

{{
  "resumo_executivo": "Texto de 2-3 frases resumindo a oportunidade",
  "pontos_positivos": ["ponto 1", "ponto 2", "ponto 3"],
  "pontos_atencao": ["ponto 1", "ponto 2"],
  "riscos_juridicos": ["risco 1", "risco 2"],
  "recomendacao_final": "Texto com recomendação clara ao investidor",
  "classificacao": "excelente|boa|moderada|alto_risco"
}}

DADOS DO IMÓVEL:
- Tipo: {tipo}
- Endereço: {endereco}, {bairro}, {cidade}/{estado}
- Área construída: {area_construida} m²
- Área do terreno: {area_terreno} m²
- Valor de avaliação: R$ {valor_avaliacao:,.2f}
- Valor mínimo de lance: R$ {valor_lance:,.2f}
- Desconto estimado: {desconto}%
- Valor de mercado estimado: R$ {valor_mercado:,.2f}
- Lucro potencial estimado: R$ {lucro_potencial:,.2f}
- ROI estimado: {roi}%
- Score interno: {score}/100
- Ocupado: {ocupado}
- Dívida do imóvel: R$ {valor_divida:,.2f}
- Fonte: {fonte}
- Data do leilão: {data_leilao}
"""


async def gerar_analise_ia(imovel_data: dict) -> dict:
    """
    Gera análise IA completa para um imóvel.
    Retorna dict com os campos da AnaliseIA.
    """
    if not settings.OPENAI_API_KEY:
        logger.warning("OPENAI_API_KEY não configurado — análise IA ignorada")
        return _analise_fallback(imovel_data)

    prompt = PROMPT_ANALISE.format(
        tipo=imovel_data.get("tipo", ""),
        endereco=imovel_data.get("endereco", ""),
        bairro=imovel_data.get("bairro", ""),
        cidade=imovel_data.get("cidade", ""),
        estado=imovel_data.get("estado", ""),
        area_construida=imovel_data.get("area_construida") or 0,
        area_terreno=imovel_data.get("area_terreno") or 0,
        valor_avaliacao=imovel_data.get("valor_avaliacao") or 0,
        valor_lance=imovel_data.get("valor_lance_minimo") or 0,
        desconto=imovel_data.get("desconto_percentual") or 0,
        valor_mercado=imovel_data.get("valor_mercado_estimado") or 0,
        lucro_potencial=imovel_data.get("lucro_potencial") or 0,
        roi=imovel_data.get("roi_estimado") or 0,
        score=imovel_data.get("score") or 0,
        ocupado="Sim" if imovel_data.get("ocupado") else "Não",
        valor_divida=imovel_data.get("valor_divida") or 0,
        fonte=imovel_data.get("fonte", ""),
        data_leilao=imovel_data.get("data_leilao", "Não informada"),
    )

    try:
        response = await client.chat.completions.create(
            model=settings.OPENAI_MODEL,
            messages=[
                {"role": "system", "content": PROMPT_SISTEMA},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            response_format={"type": "json_object"},
        )
        content = response.choices[0].message.content
        data = json.loads(content)
        tokens = response.usage.total_tokens if response.usage else 0

        return {
            "resumo_executivo": data.get("resumo_executivo"),
            "pontos_positivos": json.dumps(data.get("pontos_positivos", []), ensure_ascii=False),
            "pontos_atencao": json.dumps(data.get("pontos_atencao", []), ensure_ascii=False),
            "riscos_juridicos": json.dumps(data.get("riscos_juridicos", []), ensure_ascii=False),
            "recomendacao_final": data.get("recomendacao_final"),
            "classificacao": data.get("classificacao", "moderada"),
            "modelo_usado": settings.OPENAI_MODEL,
            "tokens_usados": tokens,
        }
    except Exception as e:
        logger.error(f"Erro na análise IA: {e}")
        return _analise_fallback(imovel_data)


def _analise_fallback(imovel_data: dict) -> dict:
    desconto = imovel_data.get("desconto_percentual") or 0
    score = imovel_data.get("score") or 0
    bairro = imovel_data.get("bairro", "")
    tipo = imovel_data.get("tipo", "imóvel")

    resumo = (
        f"{tipo.capitalize()} localizado em {bairro}. "
        f"Desconto estimado de {desconto:.1f}% em relação ao mercado. "
        f"Score de oportunidade: {score:.0f}/100."
    )

    if score >= 80:
        classificacao = "excelente"
    elif score >= 65:
        classificacao = "boa"
    elif score >= 45:
        classificacao = "moderada"
    else:
        classificacao = "alto_risco"

    return {
        "resumo_executivo": resumo,
        "pontos_positivos": json.dumps(["Desconto acima da média", "Região com demanda"]),
        "pontos_atencao": json.dumps(["Verificar matrícula", "Visitar o imóvel"]),
        "riscos_juridicos": json.dumps(["Verificar débitos de IPTU", "Analisar ônus na matrícula"]),
        "recomendacao_final": "Análise gerada automaticamente. Consulte um advogado antes de licitar.",
        "classificacao": classificacao,
        "modelo_usado": "fallback",
        "tokens_usados": 0,
    }
