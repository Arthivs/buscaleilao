from fastapi import APIRouter
from app.api.v1.endpoints import auth, imoveis, usuarios, alertas, dashboard, simulador, admin

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Autenticação"])
api_router.include_router(imoveis.router, prefix="/imoveis", tags=["Imóveis"])
api_router.include_router(usuarios.router, prefix="/usuarios", tags=["Usuários"])
api_router.include_router(alertas.router, prefix="/alertas", tags=["Alertas"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
api_router.include_router(simulador.router, prefix="/simulador", tags=["Simulador"])
api_router.include_router(admin.router, prefix="/admin", tags=["Administração"])
