"""Testes de integração para autenticação."""

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from main import app
from app.core.database import Base, get_db

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

engine_test = create_async_engine(TEST_DB_URL, echo=False)
TestingSession = async_sessionmaker(engine_test, class_=AsyncSession, expire_on_commit=False)


async def override_get_db():
    async with TestingSession() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with engine_test.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine_test.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


@pytest.mark.asyncio
async def test_registrar_usuario(client):
    async with client as c:
        resp = await c.post("/api/v1/auth/registrar", json={
            "nome": "João Silva",
            "email": "joao@teste.com",
            "senha": "senha123",
        })
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert data["usuario"]["email"] == "joao@teste.com"


@pytest.mark.asyncio
async def test_login(client):
    async with client as c:
        await c.post("/api/v1/auth/registrar", json={
            "nome": "Maria", "email": "maria@teste.com", "senha": "senha123"
        })
        resp = await c.post("/api/v1/auth/login", json={
            "email": "maria@teste.com", "senha": "senha123"
        })
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_senha_errada(client):
    async with client as c:
        await c.post("/api/v1/auth/registrar", json={
            "nome": "Carlos", "email": "carlos@teste.com", "senha": "certa"
        })
        resp = await c.post("/api/v1/auth/login", json={
            "email": "carlos@teste.com", "senha": "errada"
        })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_email_duplicado(client):
    async with client as c:
        await c.post("/api/v1/auth/registrar", json={
            "nome": "Ana", "email": "ana@teste.com", "senha": "senha123"
        })
        resp = await c.post("/api/v1/auth/registrar", json={
            "nome": "Ana2", "email": "ana@teste.com", "senha": "outra"
        })
    assert resp.status_code == 400
