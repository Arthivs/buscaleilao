"""
Serviço de disparo de alertas por e-mail, WhatsApp e Telegram.
"""

import httpx
from loguru import logger
from app.core.config import settings


async def enviar_email(destinatario: str, assunto: str, corpo: str):
    try:
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart

        msg = MIMEMultipart("alternative")
        msg["Subject"] = assunto
        msg["From"] = settings.EMAIL_FROM
        msg["To"] = destinatario
        msg.attach(MIMEText(corpo, "html"))

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.ehlo()
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(settings.EMAIL_FROM, destinatario, msg.as_string())
        logger.info(f"Email enviado para {destinatario}")
    except Exception as e:
        logger.error(f"Erro ao enviar email para {destinatario}: {e}")


async def enviar_whatsapp(telefone: str, mensagem: str):
    if not settings.ZAPI_INSTANCE_ID or not settings.ZAPI_TOKEN:
        logger.warning("Z-API não configurado")
        return
    try:
        async with httpx.AsyncClient() as client:
            await client.post(
                f"https://api.z-api.io/instances/{settings.ZAPI_INSTANCE_ID}/token/{settings.ZAPI_TOKEN}/send-text",
                json={"phone": telefone, "message": mensagem},
                timeout=10,
            )
        logger.info(f"WhatsApp enviado para {telefone}")
    except Exception as e:
        logger.error(f"Erro ao enviar WhatsApp: {e}")


async def enviar_telegram(chat_id: str, mensagem: str):
    if not settings.TELEGRAM_BOT_TOKEN:
        logger.warning("Telegram não configurado")
        return
    try:
        async with httpx.AsyncClient() as client:
            await client.post(
                f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendMessage",
                json={"chat_id": chat_id, "text": mensagem, "parse_mode": "HTML"},
                timeout=10,
            )
        logger.info(f"Telegram enviado para {chat_id}")
    except Exception as e:
        logger.error(f"Erro ao enviar Telegram: {e}")


def montar_mensagem_alerta(imovel_data: dict) -> str:
    return (
        f"🏠 <b>Nova Oportunidade — Leilão Inteligente</b>\n\n"
        f"📍 {imovel_data.get('endereco', '')}, {imovel_data.get('bairro', '')}\n"
        f"🏷️ Tipo: {imovel_data.get('tipo', '')}\n"
        f"💰 Lance mínimo: R$ {imovel_data.get('valor_lance_minimo', 0):,.2f}\n"
        f"📉 Desconto: {imovel_data.get('desconto_percentual', 0):.1f}%\n"
        f"⭐ Score: {imovel_data.get('score', 0):.0f}/100\n"
        f"📅 Data do leilão: {imovel_data.get('data_leilao', 'Não informada')}\n"
    )
