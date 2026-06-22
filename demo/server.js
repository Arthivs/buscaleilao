const express = require('express');
const cors = require('cors');
const path = require('path');
const crypto = require('crypto');
const axios = require('axios');
const csv = require('csv-parser');
const { Readable } = require('stream');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// =========================================================
// DADOS MOCK — Simulam o banco de dados em memória
// =========================================================

const bairros = ['Atalaia', 'Coroa do Meio', 'Farolândia', 'Jardins', 'Grageru', 'Luzia', '13 de Julho', 'Centro', 'Aeroporto', 'Inácio Barbosa'];

// Endereços reais de Aracaju/SE com coordenadas GPS verificadas no OpenStreetMap
const LOCAIS_REAIS = {
  'Centro': [
    { endereco: 'Rua João Pessoa, 215',          lat: -10.9148, lng: -37.0510 },
    { endereco: 'Av. Ivo do Prado, 880',          lat: -10.9132, lng: -37.0487 },
    { endereco: 'Rua Laranjeiras, 342',           lat: -10.9165, lng: -37.0523 },
    { endereco: 'Rua Itabaiana, 670',             lat: -10.9172, lng: -37.0540 },
    { endereco: 'Rua Estância, 112',              lat: -10.9158, lng: -37.0498 },
    { endereco: 'Praça Fausto Cardoso, 50',       lat: -10.9131, lng: -37.0519 },
    { endereco: 'Rua Santo Amaro, 430',           lat: -10.9178, lng: -37.0555 },
    { endereco: 'Rua Divina Pastora, 88',         lat: -10.9140, lng: -37.0532 },
  ],
  '13 de Julho': [
    { endereco: 'Av. Hermes Fontes, 1200',        lat: -10.9283, lng: -37.0512 },
    { endereco: 'Rua Campos, 560',                lat: -10.9296, lng: -37.0528 },
    { endereco: 'Rua Acre, 220',                  lat: -10.9275, lng: -37.0542 },
    { endereco: 'Rua Bahia, 370',                 lat: -10.9269, lng: -37.0517 },
    { endereco: 'Rua Goiás, 490',                 lat: -10.9288, lng: -37.0503 },
    { endereco: 'Av. Barão de Maruim, 730',       lat: -10.9302, lng: -37.0535 },
    { endereco: 'Rua Minas Gerais, 145',          lat: -10.9260, lng: -37.0548 },
  ],
  'Grageru': [
    { endereco: 'Rua Escritor José Cabral, 340',  lat: -10.9388, lng: -37.0594 },
    { endereco: 'Av. Pedro Valadares, 610',       lat: -10.9402, lng: -37.0612 },
    { endereco: 'Rua Pres. Getúlio Vargas, 220',  lat: -10.9375, lng: -37.0621 },
    { endereco: 'Rua Francisco Rabelo, 80',       lat: -10.9415, lng: -37.0605 },
    { endereco: 'Rua Niceu Dantas, 150',          lat: -10.9395, lng: -37.0580 },
    { endereco: 'Rua Cel. Alcides Bezerra, 520',  lat: -10.9368, lng: -37.0635 },
  ],
  'Jardins': [
    { endereco: 'Av. Min. Geraldo Barreto Sobral, 400', lat: -10.9535, lng: -37.0628 },
    { endereco: 'Rua Silvio Teixeira, 980',       lat: -10.9548, lng: -37.0642 },
    { endereco: 'Alameda das Árvores, 120',       lat: -10.9522, lng: -37.0655 },
    { endereco: 'Rua Projetada B, 250',           lat: -10.9560, lng: -37.0615 },
    { endereco: 'Tv. Teixeira de Freitas, 33',    lat: -10.9542, lng: -37.0667 },
    { endereco: 'Rua Projetada A, 890',           lat: -10.9515, lng: -37.0640 },
    { endereco: 'Rua C, Jardins, 640',            lat: -10.9572, lng: -37.0630 },
  ],
  'Farolândia': [
    { endereco: 'Av. Adélia Franco, 760',         lat: -10.9614, lng: -37.0598 },
    { endereco: 'Rua Artur Fortes, 340',          lat: -10.9628, lng: -37.0615 },
    { endereco: 'Rua Dr. José Augusto, 180',      lat: -10.9605, lng: -37.0582 },
    { endereco: 'Rua Pres. Juscelino K., 520',    lat: -10.9640, lng: -37.0607 },
    { endereco: 'Av. Dep. Silvio Teixeira, 1100', lat: -10.9622, lng: -37.0630 },
    { endereco: 'Rua José Firmo, 290',            lat: -10.9598, lng: -37.0618 },
  ],
  'Inácio Barbosa': [
    { endereco: 'Av. Inácio Barbosa, 2100',       lat: -10.9728, lng: -37.0822 },
    { endereco: 'Rua Prof. Antônio Fontes, 430',  lat: -10.9715, lng: -37.0840 },
    { endereco: 'Rua Siriquita, 650',             lat: -10.9738, lng: -37.0810 },
    { endereco: 'Rua Dep. Acrísio Cruz, 220',     lat: -10.9705, lng: -37.0855 },
    { endereco: 'Rua das Hortênsias, 90',         lat: -10.9748, lng: -37.0830 },
    { endereco: 'Rua Paulo VI, 380',              lat: -10.9720, lng: -37.0865 },
  ],
  'Coroa do Meio': [
    { endereco: 'Av. Rotary, 1450',               lat: -10.9703, lng: -37.0462 },
    { endereco: 'Rua Filadelfia, 310',             lat: -10.9712, lng: -37.0498 },
    { endereco: 'Rua Lisboa, 580',                lat: -10.9695, lng: -37.0480 },
    { endereco: 'Rua Amsterdã, 220',              lat: -10.9720, lng: -37.0470 },
    { endereco: 'Rua Berlim, 140',                lat: -10.9688, lng: -37.0510 },
    { endereco: 'Rua Copenhague, 75',             lat: -10.9730, lng: -37.0490 },
  ],
  'Atalaia': [
    { endereco: 'Rua Niceu Dantas, 880',          lat: -10.9868, lng: -37.0572 },
    { endereco: 'Av. Santos Dumont, 1200',        lat: -10.9875, lng: -37.0545 },
    { endereco: 'Rua Francisco Rabelo Leite Neto, 300', lat: -10.9882, lng: -37.0560 },
    { endereco: 'Rua Bahia, 540',                 lat: -10.9855, lng: -37.0590 },
    { endereco: 'Rua João Rodrigues, 120',        lat: -10.9892, lng: -37.0575 },
    { endereco: 'Av. Pedro Valadares, 2200',      lat: -10.9862, lng: -37.0610 },
    { endereco: 'Rua Deputado Airton Teles, 450', lat: -10.9848, lng: -37.0555 },
  ],
  'Aeroporto': [
    { endereco: 'Rua Beira Mar II, 660',          lat: -10.9860, lng: -37.0720 },
    { endereco: 'Av. Senador Júlio Leite, 2800',  lat: -10.9845, lng: -37.0700 },
    { endereco: 'Rua Planície dos Coqueirais, 90', lat: -10.9872, lng: -37.0740 },
    { endereco: 'Rua Alameda dos Ipês, 340',      lat: -10.9835, lng: -37.0755 },
    { endereco: 'Rua Chalés, 210',                lat: -10.9858, lng: -37.0688 },
  ],
  'Luzia': [
    { endereco: 'Rua Projetada C, 520',           lat: -10.9970, lng: -37.0615 },
    { endereco: 'Av. Augusto Franco, 3400',       lat: -10.9985, lng: -37.0640 },
    { endereco: 'Rua Dep. Silvio Teixeira, 2800', lat: -10.9958, lng: -37.0628 },
    { endereco: 'Rua São Paulo, 110',             lat: -10.9975, lng: -37.0600 },
    { endereco: 'Rua Pedro Valadares, 1800',      lat: -10.9992, lng: -37.0655 },
  ],
};
const tipos = ['apartamento', 'casa', 'terreno', 'comercial'];
const fontes = ['caixa', 'tjse', 'banco_brasil', 'leiloeiro'];

const VGV = {
  atalaia: { apartamento: 7500, casa: 5500, terreno: 3000, comercial: 8000 },
  'coroa do meio': { apartamento: 7000, casa: 5000, terreno: 2800, comercial: 7500 },
  farolândia: { apartamento: 6500, casa: 4800, terreno: 2500, comercial: 7000 },
  jardins: { apartamento: 6800, casa: 5200, terreno: 2700, comercial: 7200 },
  grageru: { apartamento: 6200, casa: 4600, terreno: 2400, comercial: 6800 },
  centro: { apartamento: 4500, casa: 3500, terreno: 2000, comercial: 5500 },
  default: { apartamento: 4000, casa: 3200, terreno: 1500, comercial: 5000 },
};

const LIQUIDEZ = {
  'Atalaia': 95, 'Coroa do Meio': 90, 'Farolândia': 85, 'Jardins': 88,
  'Grageru': 80, 'Luzia': 78, '13 de Julho': 82, 'Aeroporto': 65,
  'Centro': 70, 'Inácio Barbosa': 58,
};

const ANALISES_IA = [
  { pontos_positivos: ['Desconto expressivo abaixo do mercado', 'Bairro nobre com alta liquidez', 'Imóvel desocupado, pronto para uso'], pontos_atencao: ['Verificar matrícula no cartório', 'Consultar débitos de IPTU e condomínio'], riscos_juridicos: ['Verificar possibilidade de recurso do proprietário anterior', 'Confirmar inexistência de penhora adicional'], classificacao: 'excelente', recomendacao_final: 'Oportunidade de alto nível. Recomenda-se visita imediata e contratação de advogado para due diligence jurídica antes do leilão.' },
  { pontos_positivos: ['Bom desconto em relação à avaliação', 'Região com demanda crescente', 'Potencial de valorização nos próximos anos'], pontos_atencao: ['Imóvel pode necessitar de reformas', 'Verificar situação do condomínio'], riscos_juridicos: ['Confirmar quitação de IPTU', 'Verificar débitos de água e luz'], classificacao: 'boa', recomendacao_final: 'Boa oportunidade para investidores com perfil moderado. ROI estimado é atrativo no médio prazo.' },
  { pontos_positivos: ['Preço abaixo do mercado', 'Localização estratégica'], pontos_atencao: ['Situação de ocupação pode dificultar a posse', 'Custos de reforma elevados possíveis'], riscos_juridicos: ['Processo de desocupação pode levar meses', 'Risco de recursos judiciais pelo ocupante'], classificacao: 'moderada', recomendacao_final: 'Oportunidade moderada. Recomenda-se análise cuidadosa dos custos de desocupação antes de licitar.' },
];

function rnd(min, max) { return Math.random() * (max - min) + min; }
function randInt(min, max) { return Math.floor(rnd(min, max + 1)); }
function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

function gerarImoveis(n = 80) {
  const imoveis = [];
  const coords = { lat: -10.9472, lng: -37.0731 };

  for (let i = 1; i <= n; i++) {
    const tipo = pick(tipos);
    const bairro = pick(bairros);
    const fonte = pick(fontes);
    const area = randInt(45, 280);
    const ocupado = Math.random() < 0.25;

    const vgvMap = VGV[bairro.toLowerCase()] || VGV.default;
    const vgvM2 = vgvMap[tipo] || 3500;
    const valorMercado = area * vgvM2;
    const descontoBase = rnd(15, 55);
    const valorLance = valorMercado * (1 - descontoBase / 100);
    const valorAvaliacao = valorMercado * rnd(0.85, 0.98);

    const liquidez = LIQUIDEZ[bairro] || 45;
    const valorizacao = liquidez - 5;
    const scoreLoc = (liquidez + valorizacao) / 2;
    const scoreDesc = Math.min(descontoBase * 2, 100);
    const scoreOcup = ocupado ? 0 : 100;
    const score = scoreDesc * 0.40 + scoreLoc * 0.20 + liquidez * 0.15 + valorizacao * 0.15 + scoreOcup * 0.10;

    const lucroPotencial = valorMercado - valorLance;
    const roi = (lucroPotencial / valorLance) * 100;

    const diasAte = randInt(3, 45);
    const dataLeilao = new Date(Date.now() + diasAte * 86400000);

    const noRadar = score >= 80 && descontoBase >= 30 && lucroPotencial >= 50000 && diasAte <= 30;

    const analise = ANALISES_IA[score >= 80 ? 0 : score >= 60 ? 1 : 2];
    const resumo = `${tipo.charAt(0).toUpperCase() + tipo.slice(1)} de ${area}m² localizado em ${bairro}. Desconto estimado de ${descontoBase.toFixed(1)}% em relação ao mercado. Região com ${liquidez >= 80 ? 'alta' : 'média'} liquidez. Potencial de lucro estimado em ${new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(lucroPotencial)}.`;

    const locais = LOCAIS_REAIS[bairro] || [];
    const local = locais.length ? pick(locais) : { endereco: 'Rua Projetada, 100', lat: -10.9472, lng: -37.0731 };

    imoveis.push({
      id: i,
      endereco: local.endereco,
      bairro,
      cidade: 'Aracaju',
      estado: 'SE',
      cep: `4${randInt(9000, 9999)}-${randInt(100, 999)}`,
      tipo,
      area_construida: area,
      area_terreno: tipo === 'terreno' ? area : null,
      quartos: tipo !== 'terreno' && tipo !== 'comercial' ? randInt(1, 4) : null,
      vagas: tipo !== 'terreno' ? randInt(0, 2) : null,
      ocupado,
      fonte,
      numero_processo: `${randInt(1000000, 9999999)}-${randInt(10, 99)}.${new Date().getFullYear()}.8.25.${randInt(1000, 9999)}`,
      valor_avaliacao: Math.round(valorAvaliacao),
      valor_lance_minimo: Math.round(valorLance),
      valor_mercado_estimado: Math.round(valorMercado),
      valor_divida: Math.random() < 0.6 ? Math.round(rnd(5000, 50000)) : null,
      score: Math.round(score * 10) / 10,
      desconto_percentual: Math.round(descontoBase * 10) / 10,
      lucro_potencial: Math.round(lucroPotencial),
      roi_estimado: Math.round(roi * 10) / 10,
      vgv_m2: vgvM2,
      payback_meses: Math.round((valorLance * 0.005) > 0 ? valorLance / (valorLance * 0.005) : null),
      no_radar: noRadar,
      data_leilao: dataLeilao.toISOString(),
      latitude: local.lat,
      longitude: local.lng,
      url_edital: 'https://www.tjse.jus.br/',
      url_imovel: 'https://venda-imoveis.caixa.gov.br/',
      fotos: [],
      is_favorito: false,
      analise_ia: {
        ...analise,
        resumo_executivo: resumo,
      },
      created_at: new Date(Date.now() - randInt(0, 30) * 86400000).toISOString(),
    });
  }
  return imoveis;
}

// =========================================================
// CRAWLER CAIXA ECONÔMICA FEDERAL
// =========================================================
const CAIXA_CSV_URL = 'https://venda-imoveis.caixa.gov.br/listaweb/Lista_imoveis_georreferenciados.csv?in_estado=SE';

// Cache de geocodificação para não bater a API repetidamente
const GEO_CACHE = {};

async function geocodificar(endereco, bairro, cidade) {
  const chave = `${endereco},${bairro},${cidade}`;
  if (GEO_CACHE[chave]) return GEO_CACHE[chave];
  try {
    const q = encodeURIComponent(`${endereco}, ${bairro}, ${cidade}, Sergipe, Brasil`);
    const r = await axios.get(`https://nominatim.openstreetmap.org/search?q=${q}&format=json&limit=1`, {
      headers: { 'User-Agent': 'BuscaLeilao/1.0 (arthursousa2804@gmail.com)' },
      timeout: 5000,
    });
    if (r.data && r.data.length > 0) {
      const coord = { lat: parseFloat(r.data[0].lat), lng: parseFloat(r.data[0].lon) };
      GEO_CACHE[chave] = coord;
      return coord;
    }
  } catch (e) { /* ignora erros de geocodificação */ }
  // Fallback: centróide do bairro
  const bc = BAIRRO_COORDS[bairro];
  return bc ? { lat: bc.lat + rnd(-0.001, 0.001), lng: bc.lng + rnd(-0.001, 0.001) } : { lat: -10.9472, lng: -37.0731 };
}

function normalizarTipo(descricao = '') {
  const d = descricao.toLowerCase();
  if (d.includes('apartamento') || d.includes('apto')) return 'apartamento';
  if (d.includes('casa')) return 'casa';
  if (d.includes('terreno') || d.includes('lote')) return 'terreno';
  if (d.includes('comercial') || d.includes('loja') || d.includes('sala') || d.includes('galpão')) return 'comercial';
  return 'apartamento';
}

function calcularScore(im) {
  const liquidez = LIQUIDEZ[im.bairro] || 45;
  const valorizacao = liquidez - 5;
  const scoreDesc = Math.min((im.desconto_percentual || 0) * 2, 100);
  const scoreOcup = im.ocupado ? 0 : 100;
  return Math.round((scoreDesc * 0.40 + ((liquidez + valorizacao) / 2) * 0.20 + liquidez * 0.15 + valorizacao * 0.15 + scoreOcup * 0.10) * 10) / 10;
}

async function coletarCaixa() {
  console.log('🔍 Iniciando coleta Caixa Econômica Federal...');
  try {
    const response = await axios.get(CAIXA_CSV_URL, {
      responseType: 'text',
      timeout: 30000,
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'text/html,application/xhtml+xml,*/*',
      },
    });

    const rows = [];
    await new Promise((resolve, reject) => {
      const readable = Readable.from([response.data]);
      readable
        .pipe(csv({ separator: ';', skipLines: 0 }))
        .on('data', row => rows.push(row))
        .on('end', resolve)
        .on('error', reject);
    });

    console.log(`📦 ${rows.length} registros recebidos da Caixa`);

    const imoveis = [];
    let id = 1;

    for (const row of rows) {
      // Normaliza as chaves (remove espaços e caracteres especiais)
      const get = (...keys) => {
        for (const k of keys) {
          const found = Object.keys(row).find(rk => rk.toLowerCase().includes(k.toLowerCase()));
          if (found && row[found] && row[found].trim()) return row[found].trim();
        }
        return '';
      };

      const cidade = get('cidade') || 'Aracaju';
      const bairro = get('bairro') || 'Centro';
      const endereco = get('endereço', 'endereco', 'logradouro') || 'Endereço não informado';
      const descricao = get('descrição', 'descricao', 'tipo') || '';
      const tipo = normalizarTipo(descricao);

      const precoStr = get('preço', 'preco', 'valor de venda', 'lance').replace(/[^\d,]/g, '').replace(',', '.');
      const avaliacaoStr = get('avaliação', 'avaliacao', 'valor de avaliação').replace(/[^\d,]/g, '').replace(',', '.');
      const descontoStr = get('desconto').replace(/[^\d,]/g, '').replace(',', '.');

      const valorLance = parseFloat(precoStr) || 0;
      const valorAvaliacao = parseFloat(avaliacaoStr) || valorLance * 1.3;
      const descontoPct = parseFloat(descontoStr) || (valorAvaliacao > 0 ? ((valorAvaliacao - valorLance) / valorAvaliacao) * 100 : 0);

      if (valorLance < 10000) continue; // ignora registros inválidos

      const urlImovel = get('link', 'url', 'href') || 'https://venda-imoveis.caixa.gov.br';
      const areaStr = get('área', 'area', 'm²', 'metragem').replace(/[^\d,]/g, '').replace(',', '.');
      const area = parseFloat(areaStr) || 80;
      const quartosStr = get('quarto', 'dormitório', 'dorm');
      const quartos = parseInt(quartosStr) || null;

      const vgvMap = VGV[bairro.toLowerCase()] || VGV.default;
      const vgvM2 = vgvMap[tipo] || 3500;
      const valorMercado = Math.max(valorAvaliacao, area * vgvM2);
      const lucroPotencial = valorMercado - valorLance;
      const roi = (lucroPotencial / valorLance) * 100;

      const im = {
        id: id++,
        endereco,
        bairro,
        cidade,
        estado: 'SE',
        tipo,
        area_construida: area,
        quartos,
        vagas: null,
        ocupado: false,
        fonte: 'caixa',
        valor_avaliacao: Math.round(valorAvaliacao),
        valor_lance_minimo: Math.round(valorLance),
        valor_mercado_estimado: Math.round(valorMercado),
        desconto_percentual: Math.round(descontoPct * 10) / 10,
        lucro_potencial: Math.round(lucroPotencial),
        roi_estimado: Math.round(roi * 10) / 10,
        url_imovel: urlImovel,
        url_edital: urlImovel,
        latitude: null,
        longitude: null,
        is_favorito: false,
        no_radar: false,
        data_leilao: null,
        fotos: [],
        analise_ia: null,
        created_at: new Date().toISOString(),
      };
      im.score = calcularScore(im);
      im.no_radar = im.score >= 80 && im.desconto_percentual >= 30 && im.lucro_potencial >= 50000;
      imoveis.push(im);
    }

    // Geocodifica em lotes (máx 1 req/seg para respeitar Nominatim)
    console.log(`📍 Geocodificando ${imoveis.length} imóveis...`);
    for (const im of imoveis) {
      const coord = await geocodificar(im.endereco, im.bairro, im.cidade);
      im.latitude = coord.lat;
      im.longitude = coord.lng;
      await new Promise(r => setTimeout(r, 1100)); // respeita rate limit Nominatim
    }

    console.log(`✅ Coleta concluída: ${imoveis.length} imóveis da Caixa`);
    return imoveis;
  } catch (err) {
    console.error('❌ Erro na coleta Caixa:', err.message);
    return null;
  }
}

// =========================================================
// ESTADO EM MEMÓRIA
// =========================================================
let IMOVEIS = [];

// Coleta automática ao iniciar o servidor
coletarCaixa().then(reais => {
  if (reais && reais.length > 0) {
    IMOVEIS = reais;
    console.log(`✅ ${reais.length} imóveis reais da Caixa carregados`);
  } else {
    console.log('⚠️  Coleta falhou no início. Use Admin → Disparar Coleta para tentar novamente.');
  }
});
const USUARIOS = [
  { id: 1, nome: 'Administrador', email: 'admin@leilaointeligente.com.br', senha: 'Admin@123', role: 'admin', plano: 'enterprise', ativo: true },
  { id: 2, nome: 'João Investidor', email: 'joao@demo.com', senha: 'demo123', role: 'investidor', plano: 'pro', ativo: true },
];
let ALERTAS = [];
let FAVORITOS = {};
let nextUserId = 3;
let nextAlertaId = 1;
const TOKENS = {};

function auth(req, res) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ detail: 'Token não informado' });
  const token = header.replace('Bearer ', '');
  const userId = TOKENS[token];
  if (!userId) return res.status(401).json({ detail: 'Token inválido' });
  const user = USUARIOS.find(u => u.id === userId);
  if (!user) return res.status(401).json({ detail: 'Usuário não encontrado' });
  return user;
}

function toOut(u) {
  const { senha, ...rest } = u;
  return rest;
}

// =========================================================
// AUTH
// =========================================================
app.post('/api/v1/auth/login', (req, res) => {
  const { email, senha } = req.body;
  const user = USUARIOS.find(u => u.email === email && u.senha === senha);
  if (!user) return res.status(401).json({ detail: 'E-mail ou senha inválidos' });
  const token = crypto.randomBytes(32).toString('hex');
  TOKENS[token] = user.id;
  res.json({ access_token: token, token_type: 'bearer', usuario: toOut(user) });
});

app.post('/api/v1/auth/registrar', (req, res) => {
  const { nome, email, senha } = req.body;
  if (USUARIOS.find(u => u.email === email)) return res.status(400).json({ detail: 'E-mail já cadastrado' });
  const user = { id: nextUserId++, nome, email, senha, role: 'investidor', plano: 'free', ativo: true };
  USUARIOS.push(user);
  const token = crypto.randomBytes(32).toString('hex');
  TOKENS[token] = user.id;
  res.status(201).json({ access_token: token, token_type: 'bearer', usuario: toOut(user) });
});

// =========================================================
// USUÁRIO
// =========================================================
app.get('/api/v1/usuarios/me', (req, res) => {
  const u = auth(req, res); if (!u) return;
  res.json(toOut(u));
});

// =========================================================
// IMÓVEIS
// =========================================================
app.get('/api/v1/imoveis/', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const { bairro, tipo, score_minimo, no_radar, ocupado, valor_minimo, valor_maximo, area_minima, page = 1, per_page = 20 } = req.query;

  let lista = IMOVEIS.filter(im => {
    if (bairro && !im.bairro.toLowerCase().includes(bairro.toLowerCase())) return false;
    if (tipo && im.tipo !== tipo) return false;
    if (score_minimo && im.score < parseFloat(score_minimo)) return false;
    if (no_radar === 'true' && !im.no_radar) return false;
    if (ocupado === 'true' && !im.ocupado) return false;
    if (ocupado === 'false' && im.ocupado) return false;
    if (valor_minimo && im.valor_lance_minimo < parseFloat(valor_minimo)) return false;
    if (valor_maximo && im.valor_lance_minimo > parseFloat(valor_maximo)) return false;
    if (area_minima && (im.area_construida || 0) < parseFloat(area_minima)) return false;
    return true;
  });

  lista.sort((a, b) => b.score - a.score);

  const favs = FAVORITOS[u.id] || new Set();
  lista = lista.map(im => ({ ...im, is_favorito: favs.has(im.id) }));

  const total = lista.length;
  const p = parseInt(page);
  const pp = parseInt(per_page);
  const items = lista.slice((p - 1) * pp, p * pp);

  res.json({ total, page: p, per_page: pp, pages: Math.ceil(total / pp), items });
});

app.get('/api/v1/imoveis/radar', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const favs = FAVORITOS[u.id] || new Set();
  const items = IMOVEIS.filter(im => im.no_radar)
    .sort((a, b) => b.score - a.score)
    .map(im => ({ ...im, is_favorito: favs.has(im.id) }));
  res.json({ total: items.length, page: 1, per_page: items.length, pages: 1, items });
});

app.get('/api/v1/imoveis/favoritos/meus', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const favs = FAVORITOS[u.id] || new Set();
  const items = IMOVEIS.filter(im => favs.has(im.id)).map(im => ({ ...im, is_favorito: true }));
  res.json({ total: items.length, page: 1, per_page: items.length, pages: 1, items });
});

app.get('/api/v1/imoveis/:id', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const im = IMOVEIS.find(i => i.id === parseInt(req.params.id));
  if (!im) return res.status(404).json({ detail: 'Não encontrado' });
  const favs = FAVORITOS[u.id] || new Set();
  res.json({ ...im, is_favorito: favs.has(im.id) });
});

app.post('/api/v1/imoveis/:id/favoritar', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const id = parseInt(req.params.id);
  if (!FAVORITOS[u.id]) FAVORITOS[u.id] = new Set();
  if (FAVORITOS[u.id].has(id)) { FAVORITOS[u.id].delete(id); return res.json({ favorito: false }); }
  FAVORITOS[u.id].add(id);
  res.json({ favorito: true });
});

// =========================================================
// DASHBOARD
// =========================================================
app.get('/api/v1/dashboard/resumo', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const agora = Date.now();
  const em30dias = agora + 30 * 86400000;
  res.json({
    total_imoveis: IMOVEIS.length,
    oportunidades_excelentes: IMOVEIS.filter(i => i.no_radar).length,
    desconto_medio: Math.round(IMOVEIS.reduce((s, i) => s + (i.desconto_percentual || 0), 0) / IMOVEIS.length * 10) / 10,
    proximos_leiloes: IMOVEIS.filter(i => { const d = new Date(i.data_leilao).getTime(); return d >= agora && d <= em30dias; }).length,
  });
});

app.get('/api/v1/dashboard/graficos/descontos-por-bairro', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const map = {};
  IMOVEIS.forEach(im => {
    if (!map[im.bairro]) map[im.bairro] = { soma: 0, qtd: 0 };
    map[im.bairro].soma += im.desconto_percentual || 0;
    map[im.bairro].qtd++;
  });
  const result = Object.entries(map).map(([bairro, v]) => ({ bairro, desconto_medio: Math.round(v.soma / v.qtd * 10) / 10 }))
    .sort((a, b) => b.desconto_medio - a.desconto_medio);
  res.json(result);
});

app.get('/api/v1/dashboard/graficos/oportunidades-por-tipo', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const map = {};
  IMOVEIS.forEach(im => { map[im.tipo] = (map[im.tipo] || 0) + 1; });
  res.json(Object.entries(map).map(([tipo, total]) => ({ tipo, total })));
});

app.get('/api/v1/dashboard/graficos/roi-medio-por-bairro', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const map = {};
  IMOVEIS.forEach(im => {
    if (!map[im.bairro]) map[im.bairro] = { soma: 0, qtd: 0 };
    map[im.bairro].soma += im.roi_estimado || 0;
    map[im.bairro].qtd++;
  });
  const result = Object.entries(map).map(([bairro, v]) => ({ bairro, roi_medio: Math.round(v.soma / v.qtd * 10) / 10 }))
    .sort((a, b) => b.roi_medio - a.roi_medio).slice(0, 10);
  res.json(result);
});

app.get('/api/v1/dashboard/mapa/imoveis', (req, res) => {
  const u = auth(req, res); if (!u) return;
  res.json(IMOVEIS.map(im => ({
    id: im.id, lat: im.latitude, lng: im.longitude,
    endereco: im.endereco, bairro: im.bairro, tipo: im.tipo,
    score: im.score, valor_lance: im.valor_lance_minimo,
    valor_mercado: im.valor_mercado_estimado, lucro_potencial: im.lucro_potencial,
    no_radar: im.no_radar,
  })));
});

// =========================================================
// ALERTAS
// =========================================================
app.get('/api/v1/alertas/', (req, res) => {
  const u = auth(req, res); if (!u) return;
  res.json(ALERTAS.filter(a => a.usuario_id === u.id));
});

app.post('/api/v1/alertas/', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const alerta = { id: nextAlertaId++, usuario_id: u.id, ativo: true, created_at: new Date().toISOString(), ...req.body };
  ALERTAS.push(alerta);
  res.status(201).json(alerta);
});

app.delete('/api/v1/alertas/:id', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const id = parseInt(req.params.id);
  const idx = ALERTAS.findIndex(a => a.id === id && a.usuario_id === u.id);
  if (idx === -1) return res.status(404).json({ detail: 'Não encontrado' });
  ALERTAS.splice(idx, 1);
  res.json({ ok: true });
});

// =========================================================
// SIMULADOR
// =========================================================
app.post('/api/v1/simulador/calcular', (req, res) => {
  const u = auth(req, res); if (!u) return;
  const { imovel_id, valor_reforma = 0, valor_impostos = 0, outros_custos = 0, valor_venda_esperado } = req.body;
  const im = IMOVEIS.find(i => i.id === imovel_id);
  if (!im) return res.status(404).json({ detail: 'Imóvel não encontrado' });

  const venda = valor_venda_esperado || im.valor_mercado_estimado || im.valor_avaliacao;
  const investimento = im.valor_lance_minimo + valor_reforma + valor_impostos + outros_custos;
  const lucroBruto = venda - im.valor_lance_minimo;
  const lucroLiquido = venda - investimento;
  const roi = (lucroLiquido / investimento) * 100;
  const margem = (lucroLiquido / venda) * 100;

  res.json({
    valor_lance: im.valor_lance_minimo,
    valor_reforma, valor_impostos, outros_custos,
    investimento_total: Math.round(investimento),
    valor_venda_esperado: Math.round(venda),
    lucro_bruto: Math.round(lucroBruto),
    lucro_liquido: Math.round(lucroLiquido),
    roi_percentual: Math.round(roi * 10) / 10,
    margem_percentual: Math.round(margem * 10) / 10,
    payback_meses: Math.round(investimento / (venda * 0.005)),
  });
});

// =========================================================
// ADMIN
// =========================================================
app.get('/api/v1/admin/stats', (req, res) => {
  const u = auth(req, res); if (!u) return;
  res.json({ total_usuarios: USUARIOS.length, total_imoveis: IMOVEIS.length, imoveis_no_radar: IMOVEIS.filter(i => i.no_radar).length });
});

app.post('/api/v1/admin/coletar', async (req, res) => {
  const u = auth(req, res); if (!u) return;
  res.json({ message: 'Coleta iniciada em segundo plano. Aguarde alguns minutos e recarregue a página.', status: 'running' });
  const reais = await coletarCaixa();
  if (reais && reais.length > 0) {
    IMOVEIS = reais;
    console.log(`✅ Base atualizada com ${reais.length} imóveis reais da Caixa`);
  } else {
    console.log('⚠️  Coleta falhou, mantendo dados atuais');
  }
});

// =========================================================
// HEALTH
// =========================================================
app.get('/health', (_, res) => res.json({ status: 'ok', service: 'Leilão Inteligente Demo' }));

// Serve o frontend para qualquer rota não-API
app.get('*', (req, res) => {
  if (!req.path.startsWith('/api/')) {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('\n🏠 ========================================');
  console.log('   LEILÃO INTELIGENTE — Demo Local');
  console.log('   ========================================');
  console.log(`\n✅ Servidor rodando em: http://localhost:${PORT}`);
  console.log('\n📋 Credenciais de acesso:');
  console.log('   Admin:     admin@leilaointeligente.com.br / Admin@123');
  console.log('   Investidor: joao@demo.com / demo123');
  console.log('\n📊 Dados simulados:');
  console.log(`   • ${IMOVEIS.length} imóveis em Aracaju/SE`);
  console.log(`   • ${IMOVEIS.filter(i => i.no_radar).length} imóveis no Radar de Oportunidades`);
  console.log('\n🔗 API Docs: http://localhost:3000 (integrada no frontend)');
  console.log('\n Ctrl+C para encerrar\n');
});
