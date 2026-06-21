from pydantic_settings import BaseSettings
from typing import List
import secrets


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Leilão Inteligente"
    APP_URL: str = "http://localhost:3000"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False

    # Segurança
    SECRET_KEY: str = secrets.token_urlsafe(64)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24h
    ALGORITHM: str = "HS256"

    # Banco de dados
    DATABASE_URL: str = "postgresql+asyncpg://leilao_user:leilao_pass@localhost:5432/leilao_inteligente"

    # Redis
    REDIS_URL: str = "redis://:redis_pass@localhost:6379/0"

    # OpenAI
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-4o-mini"

    # Email
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    EMAIL_FROM: str = "noreply@leilaointeligente.com.br"

    # WhatsApp (Z-API)
    ZAPI_INSTANCE_ID: str = ""
    ZAPI_TOKEN: str = ""

    # Telegram
    TELEGRAM_BOT_TOKEN: str = ""

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://app.leilaointeligente.com.br",
    ]

    # Score – pesos configuráveis
    SCORE_PESO_DESCONTO: float = 0.40
    SCORE_PESO_LOCALIZACAO: float = 0.20
    SCORE_PESO_LIQUIDEZ: float = 0.15
    SCORE_PESO_VALORIZACAO: float = 0.15
    SCORE_PESO_OCUPACAO: float = 0.10

    # Radar de Oportunidades
    RADAR_SCORE_MINIMO: int = 80
    RADAR_DESCONTO_MINIMO: float = 30.0
    RADAR_LUCRO_MINIMO: float = 50000.0
    RADAR_DIAS_LEILAO: int = 30

    # Limites de planos
    PLAN_FREE_MAX_ALERTS: int = 3
    PLAN_PRO_MAX_ALERTS: int = 50
    PLAN_ENTERPRISE_MAX_ALERTS: int = 999

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
