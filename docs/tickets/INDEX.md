# Tickets — INDEX (67 tickets)

| # | item | título | deps | MCP |
|---|---|---|---|---|
| [0001](TICKET-0001.md) | a | Rails 8 + 4 engines + packwerk | — | neon (opc) |
| [0002](TICKET-0002.md) | b | Core models + seeds idempotentes | 0001 | neon |
| [0003](TICKET-0003-v3.md) | c | AASM + fix guard revert_match! (v3) | 0002 | — |
| [0004](TICKET-0004.md) | d | ProcessMatchPointsJob + Scoring::Engine | 0003 | — |
| [0005](TICKET-0005.md) | e | RevertMatchPointsService (discard + AuditLog) | 0003, 0004 | — |
| [0006](TICKET-0006.md) | f | Preview Bolão candidate_home/away | 0004 | — |
| [0007](TICKET-0007.md) | g | Preview Cartola Data.define | 0002 | — |
| [0008](TICKET-0008.md) | h | BroadcastUpdateService unless_exist | 0004 | — |
| [0009](TICKET-0009.md) | i | ProcessCsvImportJob streaming | 0002 | r2 (opc) |
| [0010](TICKET-0010.md) | j | ActiveAdmin + Pundit (5 policies) | 0005, 0006, 0007, 0009 | — |
| [0011](TICKET-0011.md) | k | Design system + ViewComponents 4 estados | 0001 | — |
| [0012](TICKET-0012-v2.md) | l | CI + deploy Render/Neon + R2 + Resend (v2) | 0001, 0002, 0010, 0014, 0015 | render, neon, r2, resend |
| [0013](TICKET-0013.md) | m | MCP setup + smoke tests | 0001 | neon, render, r2, resend |
| [0014](TICKET-0014.md) | — | Auth (Rails 8 native) | 0001 | — |
| [0015](TICKET-0015.md) | — | Pundit base + 5 policies vazias | 0014 | — |
| [0016](TICKET-0016.md) | — | ScoringRule model + migration | 0002 | neon (opc) |
| [0017](TICKET-0017.md) | — | Scoring::Engine (Strategy Pattern) | 0016 | — |
| [0018](TICKET-0018.md) | — | Users::AnonymizeService (LGPD) | 0014 | — |
| [0019](TICKET-0019.md) | — | Rate limiting em auth endpoints | 0014 | — |
| [0020](TICKET-0020.md) | — | bin/setup + .env.example | 0001 | — |
| [0021](TICKET-0021.md) | — | Solid Queue dashboard + Sentry | 0012 | render (opc) |
| [0022](TICKET-0022.md) | — | db/seeds.rb real | 0002 | neon (opc) |
| [0023](TICKET-0023.md) | — | Bolão: criar e entrar em pool | 0011, 0014 | neon (opc) |
| [0024](TICKET-0024.md) | — | Bolão: palpites | 0006, 0023 | — |
| [0025](TICKET-0025.md) | — | Cartola: escalação | 0007, 0011 | neon (opc) |
| [0026](TICKET-0026.md) | — | Simulador: definir escopo (ADR) | — | — |
| [0027](TICKET-0027.md) | — | Seeds de demonstração | 0023, 0024, 0025 | neon (opc) |
| [0028](TICKET-0028.md) | — | Signup público | 0011, 0014, 0019 | — |
| [0029](TICKET-0029.md) | — | Bolão com 2 faixas configuráveis (ADR 0004) | 0004, 0006, 0010, 0016 | supabase (leitura) |
| [0030](TICKET-0030.md) | — | Cartola configurável por campeonato (limites, carteira, valorização, rankings) | 0007, 0010, 0025 | supabase (leitura) |
| [0031](TICKET-0031.md) | — | Simulador v1 "e se" (ADR 0003) | 0011, 0026, 0030 | — |
| [0032](TICKET-0032.md) | — | Home pública + flag privado em campeonatos | 0011, 0031, 0035, 0038 | mobbin (indisponível) |
| [0033](TICKET-0033.md) | — | Login em /entrar + menu da conta | 0014, 0028 | — |
| [0034](TICKET-0034.md) | — | Cartola vira Esquadrão (UI, admin, 301) | 0025, 0030 | — |
| [0035](TICKET-0035.md) | — | Página pública do campeonato com rankings | 0029, 0030, 0032, 0038, 0040 | — |
| [0036](TICKET-0036.md) | — | Rebranding Craquefy | 0032, 0034, 0037 | — |
| [0037](TICKET-0037.md) | — | Interface em pt-BR (rails-i18n) | 0010, 0014 | — |
| [0038](TICKET-0038.md) | — | Consentimento de perfil público + /minha-conta | 0018, 0028 | — |
| [0039](TICKET-0039.md) | — | Scouts oficiais do Esquadrão | 0004, 0010, 0030 | — |
| [0040](TICKET-0040.md) | — | Capitão + valorização por regressão à média (ADR 0005) | 0030, 0039 | — |
| [0041](TICKET-0041.md) | — | Simulador por campeonato (lista + carrossel de rodadas) + rodapé com autor e Pix | 0031, 0032, 0035 | — |
| [0042](TICKET-0042.md) | — | Jogos de hoje agrupados por campeonato + 5 campeonatos pequenos (6–12 times, públicos e privados) no seed local | 0035, 0041 | — |
| [0043](TICKET-0043.md) | — | Simulador pelos cards da home + rodadas passadas no carrossel + scroll snap na home | 0041, 0042 | — |
| [0044](TICKET-0044.md) | — | Simulador: tabela projetada no lugar da atual + "Zerar simulação" | 0043 | — |
| [0045](TICKET-0045.md) | — | Fuso do app em Brasília ("hoje", horários exibidos, CSV) | 0042 | — |
| [0046](TICKET-0046.md) | — | Scroll snap da home por proximidade (era obrigatório) | 0043 | — |
| [0047](TICKET-0047.md) | — | Classificação no card de campeonato da home, antes dos Top 3 | 0035, 0046 | — |
| [0048](TICKET-0048.md) | — | Jogos de hoje numa faixa horizontal única, com o campeonato em cada card | 0042 | — |
| [0049](TICKET-0049.md) | — | Jogos de hoje em faixa sem fim (volta do último ao primeiro) | 0048 | — |
| [0050](TICKET-0050.md) | — | Jogos de hoje sem barra de rolagem | 0049 | — |
| [0051](TICKET-0051.md) | — | Jogos de hoje: cards inteiros e setas de um card por vez | 0050 | — |
| [0052](TICKET-0052.md) | — | Scouts no seed demo, para o ranking de atletas da home | 0032, 0042 | — |
| [0053](TICKET-0053.md) | — | Esquadrão só com jogadores dos times do campeonato | 0025, 0040 | — |
| [0054](TICKET-0054.md) | — | Top 3 Bolão e Esquadrão no seed de todos os campeonatos | 0042, 0052, 0053 | — |
| [0055](TICKET-0055.md) | — | "Como funciona" entre "Três jeitos de jogar" e "Jogos de hoje" | 0032 | — |
| [0056](TICKET-0056.md) | A | Papéis (enum) e `manager_id` no campeonato | 0014, 0015 | — |
| [0057](TICKET-0057.md) | B | Pedido e aprovação de gestor | 0056 | — |
| [0058](TICKET-0058.md) | C | Policies com escopo por campeonato | 0056, 0015, 0010 | — |
| [0059](TICKET-0059.md) | D | Namespace `/gestor` e logins por área | 0058, 0010, 0033 | — |
| [0060](TICKET-0060.md) | E | Painel do gestor e premiação | 0059 | — |
| [0061](TICKET-0061.md) | F | Gestor: scouts, finalizar e reverter | 0039, 0059, 0058 | — |
| [0062](TICKET-0062.md) | G | Tabela de comentários do ActiveAdmin | 0010, 0059 | — |
| [0063](TICKET-0063.md) | A | Tema ActiveAdmin (Tailwind v4 / Placar) | 0010, 0011 | — |
| [0064](TICKET-0064.md) | B | Layout header/nav/footer unificado | 0063 | — |
| [0065](TICKET-0065.md) | C | Tabelas e formulários Placar | 0063, 0064 | — |
| [0066](TICKET-0066.md) | D | Dashboards admin e gestor | 0065, 0060 | — |
| [0067](TICKET-0067.md) | E | StatusBadge + Leaderboard medalhas | 0065, 0011 | — |

## Ordem de execução (topológica; numeração não é ordem)
- 0001 → {0002, 0011, 0013, 0014, 0020}
- 0002 → {0003, 0007, 0009, 0016, 0022} · 0014 → {0015, 0018, 0019}
- 0003 → 0004 → {0005, 0006, 0008} · 0016 → 0017
- {0005, 0006, 0007, 0009} → 0010 → 0012 (+ 0014, 0015) → 0021
- 0013 não bloqueia nenhum ticket
- UI/demo: {0011, 0014} → 0023 → 0024 (+ 0006) · {0007, 0011} → 0025 · {0023, 0024, 0025} → 0027
- 0026 sem deps e não bloqueia nenhum ticket (tickets derivados saem do ADR)
- Lacunas de produto: {0011, 0014, 0019} → 0028 · {0004, 0006, 0010, 0016} → 0029 · {0007, 0010, 0025} → 0030 → 0031 (+ 0011, 0026)
- Craquefy (ordem das branches): 0032 (flag) → 0034 → 0037 → 0033 → 0038 → 0039 → 0040 → 0035 → 0032 (home) → 0036 → 0041 → 0042 → 0043 → 0044 → 0045 → 0046 → 0047 → 0048 → 0049 → 0050 → 0051 → 0052 → 0053 → 0054 → 0055
- RBAC (3 níveis): 0056 → 0057 → 0058 → 0059 → 0060 → 0061 → 0062
- UI Admin/Gestor (Placar): 0063 → 0064 → 0065 → 0066 → 0067
