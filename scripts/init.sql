-- Inicialização do banco de dados Leilão Inteligente
-- Este script é executado automaticamente pelo PostgreSQL no primeiro boot

-- Extensões
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- busca textual fuzzy
CREATE EXTENSION IF NOT EXISTS "unaccent";   -- busca sem acentos

-- Usuário admin padrão (senha: Admin@123 — ALTERE EM PRODUÇÃO)
-- Hash bcrypt de 'Admin@123'
INSERT INTO usuarios (nome, email, senha_hash, role, plano, ativo, created_at, updated_at)
VALUES (
    'Administrador',
    'admin@leilaointeligente.com.br',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYpfQN.bPT5OSXO',
    'admin',
    'enterprise',
    true,
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;
