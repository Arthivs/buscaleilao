from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from contextlib import asynccontextmanager
from loguru import logger

from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"🚀 Iniciando {settings.APP_NAME}")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    logger.info("Encerrando aplicação")


app = FastAPI(
    title=settings.APP_NAME,
    description="Plataforma SaaS de identificação automática de oportunidades em leilões imobiliários",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": settings.APP_NAME}
