# Design Direction 0001 — "Placar de Domingo"

Referência: placa de estádio + grafismo de TV esportiva (mesa redonda de domingo) + jornal impresso (revista **Placar**, diário **Lance!**). Informação densa, hierarquia editorial, números protagonistas.

## 1. Paleta 60-30-10 (fora do eixo azul/violeta)
| papel | token | hex | uso |
|---|---|---|---|
| 60% base | `paper` | #F4F1EA | fundo papel-jornal (admin, páginas) |
| 30% estrutura | `pitch` (verde-campo) | #0B6B3A | header, nav, faixas de placar, tabelas zebradas |
| 10% acento único | `cartola` (laranja-cartola) | #E85D04 | CTA primário, "AO VIVO", destaque de líder |
| tinta | `ink` | #161616 | texto corpo e títulos |
| grafite | `graphite` | #4A4A45 | texto secundário, regras finas |
| regra | `rule` | #D9D3C4 | bordas, fios de tabela |
| noite | `night` | #0E1A13 | fundo scoreboard TV (modo escuro) |
| estados | `win` #0B6B3A · `draw` #8A8577 · `loss` #A4161A | | só ícone+texto, nunca cor sozinha |

- Contraste: `paper` × `ink` 16.0:1 · branco × `pitch` 6.6:1 · `ink` × `cartola` 5.2:1 · `paper` × `night` 15.8:1 (texto sobre laranja sempre `ink`; laranja como texto só ≥24px bold)
- Um único acento por tela. Laranja nunca em área > 10%.

## 2. Tipografia
| papel | família | fallback | uso |
|---|---|---|---|
| display serif | **Fraunces** (opsz 72-144, wght 600-800) | Bitter, Georgia, serif | manchetes, nomes de times no placar, títulos de seção |
| body humanista | **Source Sans 3** (400/600/700) | IBM Plex Sans, system-ui | corpo, tabelas, formulários, admin |
| numerais | Source Sans 3 `font-variant-numeric: tabular-nums lining-nums` | | placares, pontuação, ranking, odds |

- PROIBIDO: Inter, Roboto, Space Grotesk como default
- Escala (rem): 0.75 · 0.875 · 1 · 1.25 · 1.5 · 2 · 3 · 4.5 (placar TV: 6–9)
- Manchete: Fraunces 800, tracking -0.02em, caixa alta só em chapéus (kicker) Source Sans 700 0.08em

## 3. Grid e densidade
- 12 colunas, gutter 24px (admin) / 16px (mobile), max 1280px
- Admin: quebras assimétricas 8/4 (conteúdo/contexto) e 3/9 (filtros/tabela); nunca 3 cards iguais lado a lado
- Scoreboard TV: densidade alta, 16:9, linhas de 64px, placar 2/8/2 (brasão/nomes+placar/minuto), legível a 3m
- Ranking: tabela tipo classificação de jornal (posição, brasão, nome, P, J, V, E, D, saldo) com fios finos

## 4. Tokens
| grupo | valores |
|---|---|
| espaçamento (base 4/8) | 4, 8, 12, 16, 24, 32, 48, 64 |
| raios | `sm` 4 · `md` 8 · `lg` 16 (lg só em modais/painéis) |
| sombras (sutis, neutras) | `sm` 0 1px 2px rgb(22 22 22 / .06) · `md` 0 2px 6px rgb(22 22 22 / .08) |
| motion | `fast` 120ms · `base` 150ms · `slow` 180ms · easing cubic-bezier(.2,.8,.2,1); respeita `prefers-reduced-motion` |
| bordas | 1px `rule`; fio grosso 3px `ink` sob manchetes (estilo jornal) |

## 5. Imagem
- Brasões oficiais (SVG/PNG) dos clubes e fotos reais de partida (R2), nunca ilustração genérica/3D
- Fotos com legenda e crédito (padrão jornal); P&B permitido em arquivo histórico

## 6. Checklist ANTI-AI
### Proibido
- [x] Gradiente roxo/rosa/violeta (qualquer gradiente decorativo)
- [x] Glassmorphism / backdrop-blur decorativo
- [x] Hero com 3 cards + ícones
- [x] Gradient text
- [x] Emoji decorativo (ícones: SVG Lucide/Heroicons)
- [x] Glow / neon
- [x] Sombras coloridas
- [x] Inter/Roboto como única fonte
- [x] "Powered by AI" ou selo similar

### Obrigatório
- [x] Contraste editorial (serif display × sans corpo, fio grosso sob manchete)
- [x] Fotos e brasões reais
- [x] Acento único 60-30-10 (laranja-cartola ≤10%)
- [x] Numerais tabulares em todo número
- [x] Espaço negativo generoso fora do scoreboard
- [x] Referência cultural brasileira: Placar, Lance!, placa de estádio, mesa redonda de domingo, vocabulário "rodada", "zebra", "lanterna"
