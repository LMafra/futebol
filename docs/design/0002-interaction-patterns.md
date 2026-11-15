# Interaction Patterns 0002 — Console operacional

Fonte de verdade para padrões de interação do Admin e do Gestor. Cor e tipografia: [0001-direction.md](0001-direction.md). Componentes: [0003-components-specs.md](0003-components-specs.md).

## 1. Modelo mental do gestor

Quatro perguntas matinais que a home deve responder sem navegação:

1. **O que está atrasado?** — partidas ao vivo / aguardando lances / aguardando finalização.
2. **O que preciso aprovar?** — pedidos, inconsistências, gestores (Admin).
3. **O que vem a seguir?** — próxima rodada em Xh, próximas partidas.
4. **Está tudo em dia?** — KPIs em zero com confirmação visual ("✓" / "Tudo em dia").

Implicação: a home é um **console de trabalho**, não um sumário genérico. Hero curto + KPIs acionáveis + Action Center + navegação por tarefa.

## 2. Hierarquia de dashboard

Ordem do primeiro viewport:

1. **Hero** — título da área + um CTA contextual (ex.: "Criar campeonato").
2. **3–4 KPIs acionáveis** — número + label + ação; clique filtra o Action Center via URL param.
3. **Action Center** — pendências agrupadas por urgência (crítica / alta / média); vazio = EmptyState.
4. **Navegação por tarefa** — sidebar/menus por domínio (Campeonatos, Times, Participantes, Configurações); no mobile, bottom nav.

Zero em KPI: card permanece visível com "0", check SVG e "Tudo em dia" — nunca some.

## 3. Padrões de ação

| tipo | padrão |
|---|---|
| Crítica (finalizar partida, pontuar em cascata) | **Preview** antes de confirmar: placar + resumo de impacto + botão imperativo |
| Individual / local (desfazer lance, editar campo) | **Undo 5s** opcional via toast; não usar para cascata |
| Cascata / reversão | **Confirmação com justificativa** obrigatória (mín. 20 caracteres); sem undo de 5s |
| Rótulos | Imperativos **Verbo + Substantivo** ("Finalizar e Pontuar Partida", "Reverter Finalização") |

Ação primária visível na linha; secundárias no kebab (⋯).

## 4. Padrões de feedback

| evento | feedback |
|---|---|
| Sucesso de ação de linha | **Inline** no status (badge via Turbo Stream) — primário; **toast** modeless 4–5s — secundário |
| Erro de validação de formulário | **Inline** sob o campo + **banner** de resumo no topo; **nunca toast** |
| Ação de linha | **Nunca** banner no topo da página |

Toast: sucesso / erro / info; desaparece em 4–5s; não bloqueia.

## 5. Padrões de navegação

- Filtros em **barra horizontal** acima da tabela (nunca escondidos só no sidebar).
- **Chips** de filtros ativos + "Limpar todos".
- Filtros espelhados em **URL params** (compartilháveis, refresh-safe).
- **Views salvas** em abas (ex.: Minhas Pendências, Rodada Atual, Todas as Partidas).
- Alternância **Lista | Por Rodada**.
- Paginação **numerada** com texto "Exibindo X–Y de Z".
- Empty state com mensagem contextual + CTA ("Limpar Filtros" ou ação primária).

## 6. Padrões mobile (`<768px`)

- Tabelas densas → **cards empilhados** (data/hora, confronto, badge, placar, ação).
- **Bottom nav** com 3–4 itens + drawer "Mais".
- Ação primária **dentro do card**, alvo ≥44pt.
- **Sem swipe** para ação crítica; **sem FAB** em listagens.

## 7. Padrões de acessibilidade

- Badges **triplos**: ícone + texto + cor (contraste ≥4.5:1 em cada combinação).
- Números de tabela ≥7:1 (`ink` / `graphite`).
- `<abbr title="…">` em cabeçalhos abreviados + sublinhado pontilhado.
- Rótulos imperativos em botões e links de ação.
- Foco visível; não depender só de cor para situação ou erro.
