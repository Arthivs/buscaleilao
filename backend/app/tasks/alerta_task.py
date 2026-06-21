"""
Task para verificar alertas e disparar notificações.
"""

import asyncio
from datetime import datetime
from loguru import logger
from sqlalchemy import select, and_

from app.tasks.celery_app import celery_app
from app.core.database import AsyncSessionLocal
from app.models.alerta import Alerta, CanalAlertaEnum
from app.models.imovel import Imovel
from app.models.usuario import Usuario
from app.services.alerta_service import enviar_email, enviar_whatsapp, enviar_telegram, montar_mensagem_alerta


async def _verificar():
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Alerta).where(Alerta.ativo == True)
        )
        alertas = result.scalars().all()

        for alerta in alertas:
            usuario_result = await db.execute(select(Usuario).where(Usuario.id == alerta.usuario_id))
            usuario = usuario_result.scalar_one_or_none()
            if not usuario or not usuario.ativo:
                continue

            # Buscar imóveis que atendem aos critérios do alerta
            conditions = [Imovel.ativo == True]
            if alerta.bairro:
                conditions.append(Imovel.bairro.ilike(f"%{alerta.bairro}%"))
            if alerta.cidade:
                conditions.append(Imovel.cidade.ilike(f"%{alerta.cidade}%"))
            if alerta.estado:
                conditions.append(Imovel.estado == alerta.estado)
            if alerta.tipo_imovel:
                conditions.append(Imovel.tipo == alerta.tipo_imovel)
            if alerta.valor_minimo:
                conditions.append(Imovel.valor_lance_minimo >= alerta.valor_minimo)
            if alerta.valor_maximo:
                conditions.append(Imovel.valor_lance_minimo <= alerta.valor_maximo)
            if alerta.score_minimo:
                conditions.append(Imovel.score >= alerta.score_minimo)
            if alerta.desconto_minimo:
                conditions.append(Imovel.desconto_percentual >= alerta.desconto_minimo)

            # Apenas imóveis criados após o último disparo
            if alerta.ultimo_disparo:
                conditions.append(Imovel.created_at > alerta.ultimo_disparo)

            imoveis_result = await db.execute(
                select(Imovel).where(and_(*conditions)).limit(5)
            )
            imoveis_encontrados = imoveis_result.scalars().all()

            if not imoveis_encontrados:
                continue

            for imovel in imoveis_encontrados:
                mensagem = montar_mensagem_alerta({
                    "endereco": imovel.endereco,
                    "bairro": imovel.bairro,
                    "tipo": str(imovel.tipo),
                    "valor_lance_minimo": imovel.valor_lance_minimo,
                    "desconto_percentual": imovel.desconto_percentual,
                    "score": imovel.score,
                    "data_leilao": imovel.data_leilao,
                })

                if alerta.canal == CanalAlertaEnum.email:
                    assunto = f"🏠 Nova oportunidade: {imovel.bairro or imovel.cidade} — Score {imovel.score:.0f}"
                    await enviar_email(usuario.email, assunto, mensagem)
                elif alerta.canal == CanalAlertaEnum.whatsapp and usuario.telefone:
                    await enviar_whatsapp(usuario.telefone, mensagem)
                elif alerta.canal == CanalAlertaEnum.telegram and usuario.telegram_chat_id:
                    await enviar_telegram(usuario.telegram_chat_id, mensagem)

            alerta.ultimo_disparo = datetime.utcnow()

        await db.commit()
        logger.info(f"Verificação de alertas concluída. {len(alertas)} alertas processados.")


@celery_app.task(name="app.tasks.alerta_task.verificar_e_disparar_alertas")
def verificar_e_disparar_alertas():
    asyncio.get_event_loop().run_until_complete(_verificar())
