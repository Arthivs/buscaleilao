# 🏠 Leilão Inteligente

**Plataforma SaaS de identificação automática de oportunidades em leilões imobiliários**  
Foco inicial: Aracaju/SE | Arquitetura preparada para expansão nacional

---

## 📐 Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         NGINX (proxy)                        │
│              porta 80 → /api/* → Backend                    │
│                        /* → Frontend                        │
└──────────────┬─────────────────────────┬───────────────────┘
               │                         │
    ┌──────────▼──────────┐   ┌──────────▼──────────┐
    │   FastAPI Backend    │   │   Flutter Web App    │
    │    Python 3.11       │   │   Build Estático     │
    │    porta 8000        │   │   servido via Nginx  │
    └──────────┬──────────┘   └─────────────────────┘
               │
    ┌──────────▼──────────────────────────────┐
    │              PostgreSQL 15               │
    │  Tabelas: imoveis, usuarios, favoritos, │
    │           alertas, analises_ia          │
    └─────────────────────────────────────────┘
               │
    ┌──────────▼──────────┐
    │       Redis 7        │
    │  Cache + Filas       │
    │  Celery broker       │
    └──────────┬──────────┘
               │
    ┌──────────▼──────────┐
    │   Celery Workers     │
    │  - Crawlers (6h/dia) │
    │  - Alertas (30min)   │
    │  - Score (7h/dia)    │
    └─────────────────────┘
```

---

## 🗂️ Estrutura do Projeto

```
leilao-inteligente/
├── docker-compose.yml          # Orquestração completa
├── .env.example                # Template de variáveis
├── backend/
│   ├── main.py                 # Entry point FastAPI
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── alembic/                # Migrações de banco
│   ├── tests/                  # Testes automatizados
│   └── app/
│       ├── core/
│       │   ├── config.py       # Settings (Pydantic)
│       │   ├── database.py     # SQLAlchemy async
│       │   ├── security.py     # JWT + bcrypt
│       │   └── redis.py        # Cache
│       ├── models/             # ORM SQLAlchemy
│       │   ├── imovel.py       # Imóvel + enums
│       │   ├── usuario.py      # Usuário + planos
│       │   ├── favorito.py
│       │   ├── alerta.py
│       │   └── analise_ia.py
│       ├── schemas/            # Pydantic schemas
│       ├── api/v1/endpoints/   # REST endpoints
│       │   ├── auth.py         # Login / Registro
│       │   ├── imoveis.py      # CRUD + Radar
│       │   ├── dashboard.py    # KPIs + Gráficos + Mapa
│       │   ├── alertas.py      # Alertas configuráveis
│       │   ├── simulador.py    # Simulador de investimento
│       │   ├── usuarios.py     # Perfil do usuário
│       │   └── admin.py        # Painel admin
│       ├── services/
│       │   ├── score_service.py    # Motor de score 0-100
│       │   ├── mercado_service.py  # Estimativa de valor
│       │   ├── ia_service.py       # Análise OpenAI
│       │   └── alerta_service.py   # Email/WhatsApp/Telegram
│       ├── crawlers/
│       │   ├── base_crawler.py    # Classe base Playwright
│       │   ├── caixa_crawler.py   # Caixa Econômica Federal
│       │   └── tjse_crawler.py    # Tribunal de Justiça SE
│       └── tasks/
│           ├── celery_app.py      # Config Celery + agendamento
│           ├── coleta_task.py     # Task de coleta diária
│           └── alerta_task.py     # Task de disparo de alertas
├── frontend/
│   ├── Dockerfile
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── app/
│       │   ├── app.dart          # Root widget
│       │   └── routes.dart       # GoRouter + guards
│       ├── core/
│       │   ├── theme.dart        # Design system
│       │   └── api_client.dart   # Dio + JWT interceptor
│       ├── models/               # DTOs Dart
│       ├── providers/            # Riverpod state
│       │   ├── auth_provider.dart
│       │   └── imovel_provider.dart
│       ├── screens/
│       │   ├── auth/             # Login + Registro
│       │   ├── dashboard/        # KPIs + Radar
│       │   ├── imoveis/          # Lista + Detalhe
│       │   ├── mapa/             # OpenStreetMap
│       │   ├── simulador/        # Calculadora de ROI
│       │   └── alertas/          # Gerenciar alertas
│       └── widgets/
│           ├── main_shell.dart   # Nav lateral/bottom
│           └── imovel_card.dart  # Card de oportunidade
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf               # Proxy reverso + rate limiting
└── scripts/
    └── init.sql                 # Seed inicial (admin)
```

---

## 🚀 Implantação em Produção (VPS Linux)

### Pré-requisitos
- VPS com Ubuntu 22.04+ (mínimo 2 vCPU, 4GB RAM)
- Docker 24+ e Docker Compose 2.20+
- Domínio apontando para o IP da VPS

### 1. Clonar e configurar

```bash
git clone <seu-repositorio> /opt/leilao-inteligente
cd /opt/leilao-inteligente

# Configurar variáveis de ambiente
cp .env.example .env
nano .env
```

**Preencha obrigatoriamente:**
- `POSTGRES_PASSWORD` — senha forte para o banco
- `REDIS_PASSWORD` — senha forte para o Redis
- `SECRET_KEY` — string aleatória de 64+ caracteres (`openssl rand -hex 32`)
- `OPENAI_API_KEY` — sua chave da OpenAI

### 2. Build e subir

```bash
docker compose up -d --build

# Verificar status
docker compose ps
docker compose logs -f backend
```

### 3. Aplicar migrações

```bash
docker compose exec backend alembic upgrade head
```

### 4. Verificar

```bash
# Health check da API
curl http://localhost:8000/health

# Swagger UI
open http://SEU_DOMINIO/api/docs
```

### 5. Primeiro acesso

- URL: `http://SEU_DOMINIO`
- Admin: `admin@leilaointeligente.com.br`
- Senha padrão: `Admin@123` — **altere imediatamente!**

---

## 🔑 Credenciais e Segurança

| Serviço | Padrão | Onde alterar |
|---------|--------|--------------|
| Admin app | `Admin@123` | Painel do usuário |
| PostgreSQL | definido no `.env` | `.env` |
| Redis | definido no `.env` | `.env` |

> ⚠️ **NUNCA** use as senhas padrão em produção.

---

## 🤖 Motor de Score (0–100)

| Critério | Peso | Como é calculado |
|----------|------|-----------------|
| Desconto | 40% | Linear: 0%→0pts, 50%+→100pts |
| Localização | 20% | Média de liquidez+valorização do bairro |
| Liquidez | 15% | Índice do bairro (tabela interna) |
| Valorização | 15% | Tendência histórica do bairro |
| Ocupação | 10% | Desocupado=100pts, Ocupado=0pts |

**Pesos configuráveis** em `app/core/config.py` ou via variáveis de ambiente.

---

## 📡 Radar de Oportunidades

Imóveis que atendem **simultaneamente**:
- Score ≥ 80
- Desconto ≥ 30%
- Lucro potencial ≥ R$ 50.000
- Leilão nos próximos 30 dias

Destaque na tela inicial e badge no card.

---

## ⏰ Agendamentos Automáticos

| Task | Horário | Descrição |
|------|---------|-----------|
| Coleta completa | 6h diário | Roda todos os crawlers |
| Disparo de alertas | A cada 30min | Verifica e notifica usuários |
| Recálculo de scores | 7h diário | Atualiza pontuações |

---

## 🔌 APIs Documentadas

Acesse `http://SEU_DOMINIO/api/docs` para o Swagger interativo.

Principais endpoints:

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/v1/auth/registrar` | Criar conta |
| POST | `/api/v1/auth/login` | Login |
| GET | `/api/v1/imoveis/` | Listar com filtros |
| GET | `/api/v1/imoveis/radar` | Radar de oportunidades |
| GET | `/api/v1/imoveis/{id}` | Detalhe do imóvel |
| POST | `/api/v1/imoveis/{id}/favoritar` | Favoritar/desfavoritar |
| GET | `/api/v1/dashboard/resumo` | KPIs |
| GET | `/api/v1/dashboard/mapa/imoveis` | Dados para mapa |
| POST | `/api/v1/simulador/calcular` | Simular ROI |
| POST | `/api/v1/alertas/` | Criar alerta |
| POST | `/api/v1/admin/coletar` | Disparar coleta manual |

---

## 🧪 Executar Testes

```bash
cd backend
pip install -r requirements.txt
pytest tests/ -v --cov=app --cov-report=html
```

---

## 📈 Monitoramento

- **Flower** (Celery): `http://SEU_DOMINIO:5555`
- **Logs**: `docker compose logs -f celery_worker`
- **Banco**: `docker compose exec postgres psql -U leilao_user -d leilao_inteligente`

---

## 🗺️ Roadmap de Expansão

### Fase 1 — Aracaju (atual)
- [x] Crawlers: Caixa, TJSE
- [x] Score automático
- [x] Análise IA por imóvel
- [x] Radar de oportunidades
- [x] Alertas multicanal

### Fase 2 — Sergipe completo
- [ ] Crawler TJSE paginado
- [ ] Crawlers leiloeiros locais
- [ ] Cobertura de municípios do interior

### Fase 3 — Brasil
- [ ] Módulo multi-cidades (campo `cidade` já preparado)
- [ ] Crawlers por estado (TRF5, TJSP, etc.)
- [ ] API de preços imobiliários (VivaReal/ZAP)
- [ ] Dashboard por cidade/estado

### Fase 4 — Enterprise
- [ ] White-label para imobiliárias
- [ ] API pública para parceiros
- [ ] Relatórios PDF exportáveis
- [ ] Integração com cartório digital

---

## 📄 Licença

Proprietário — Todos os direitos reservados.
