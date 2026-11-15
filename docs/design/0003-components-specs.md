# Components Specs 0003 — Console operacional

Inventário dos componentes do console Admin/Gestor. Tokens e estados base: [0001-direction.md](0001-direction.md). Padrões: [0002-interaction-patterns.md](0002-interaction-patterns.md).

Convenção: texto de UI em pt-BR (glossário); chaves internas em inglês.

---

## 1. KpiCardComponent

| | |
|---|---|
| **Props** | `value:` (Integer/String), `label:`, `action_text:`, `action_path:`, `status:` (`normal` / `zero` / `alert`) |
| **Estados** | `normal` — número + label + CTA; `zero` — "0" + check SVG + "Tudo em dia"; `alert` — ênfase `cartola`/`loss` |
| **Tokens** | número `text-4xl font-numeric text-ink` (≥7:1); label `text-sm text-graphite`; CTA `text-cartola`; card clicável → filtra Action Center via URL |
| **Exemplo** | `render Ui::KpiCardComponent.new(value: 3, label: "Partidas pendentes", action_text: "Ver fila", action_path: "?urgency=high", status: :alert)` |

---

## 2. ActionCenterComponent

| | |
|---|---|
| **Props** | `groups:` Hash/Array por urgência (`critical` / `high` / `medium`); cada item: `title:`, `context:`, `action_text:`, `action_path:` |
| **Estados** | com itens (seções por urgência); `empty` → `EmptyStateComponent` |
| **Tokens** | título seção `font-display`; item borda `rule`; botão primário `bg-cartola text-ink` |
| **Exemplo** | `render Ui::ActionCenterComponent.new(groups: { critical: [...], high: [...] })` |

---

## 3. StatusBadgeComponent

| | |
|---|---|
| **Props** | `status:` (`scheduled` / `live` / `pending_scouts` / `finished` / `reverted`; alias `scored` → finished pontuada se necessário), `label:` opcional |
| **Estados** | cada status com **ícone + texto + cor** (tripla); loading/empty/error via `BaseComponent` |
| **Tokens** | `scheduled`: relógio + "AGENDADA" + `bg-rule text-ink`; `live`: ponto + "AO VIVO" + `bg-pitch/10 text-pitch` ou fill cartola+ink; `pending_scouts`: prancheta + "AGUARDANDO LANCES" + `bg-cartola/10 text-cartola` (texto ≥4.5:1); `finished`: bandeira + "FINALIZADA" + `bg-pitch/10 text-pitch`; `reverted`: alerta + "REVERTIDA" + `bg-red-50 text-red-800` |
| **Exemplo** | `render Ui::StatusBadgeComponent.new(status: :live)` |

---

## 4. AdminTableComponent

| | |
|---|---|
| **Props** | `headers:`, `rows:`, `texts:`, `table_role:`; coluna de ações (primária + kebab) |
| **Estados** | default; empty; loading (skeleton) |
| **Tokens** | cabeçalho `bg-pitch text-paper font-display text-xs uppercase`; zebra `bg-paper`/`bg-white`; números `text-right tabular-nums text-ink` |
| **Exemplo** | `render Ui::AdminTableComponent.new(headers: [...], rows: [...])` |

---

## 5. FilterBarComponent

| | |
|---|---|
| **Props** | `q:` busca; `filters:` selects (Campeonato, Rodada, Situação); `active_chips:`; `clear_path:`; `views:` abas salvas; `layout:` (`list` / `round`) |
| **Estados** | default; com chips; empty (sem resultados → EmptyState + "Limpar Filtros") |
| **Tokens** | linha 1 controles; linha 2 chips `bg-rule` + "Limpar todos" `text-cartola`; URL params |
| **Exemplo** | `render Ui::FilterBarComponent.new(filters: [...], active_chips: [...], clear_path: matches_path)` |

---

## 6. FormFieldComponent

| | |
|---|---|
| **Props** | `name:`, `label:`, `value:`, `hint:`, `error:`, `state:` |
| **Estados** | default, hover, focus, disabled, error, loading, empty (7) |
| **Tokens** | borda `rule`; error `border-loss` + mensagem `text-sm text-loss`; focus ring 2px |
| **Exemplo** | `render Ui::FormFieldComponent.new(name: :name, label: "Nome", error: "obrigatório", state: :error)` |

---

## 7. FormErrorSummaryComponent

| | |
|---|---|
| **Props** | `count:`, `messages:` (opcional), `title:` |
| **Estados** | default (visível só com erros); empty = não renderiza |
| **Tokens** | banner topo `border-loss bg-red-50 text-ink`; "N campos precisam de atenção" |
| **Exemplo** | `render Ui::FormErrorSummaryComponent.new(count: 2)` |

---

## 8. ToastComponent

| | |
|---|---|
| **Props** | `message:`, `variant:` (`success` / `error` / `info` / `notice` / `alert`) |
| **Estados** | visível 4–5s; dismissível |
| **Tokens** | canto; modeless; sem bloquear; nunca para validação de formulário |
| **Exemplo** | `render Ui::ToastComponent.new(message: "Partida finalizada", variant: :success)` |

---

## 9. EmptyStateComponent

| | |
|---|---|
| **Props** | `title:`, `description:`; slot `action` (CTA) |
| **Estados** | default (SVG + título + descrição + CTA opcional) |
| **Tokens** | ícone SVG (não emoji); tipografia body; CTA `bg-cartola` ou link `text-cartola` |
| **Exemplo** | `render Ui::EmptyStateComponent.new(title: "Nada na fila", description: "Tudo em dia.")` |

---

## 10. BottomNavComponent

| | |
|---|---|
| **Props** | `items:` até 4 (`label:`, `path:`, `icon:`, `current:`); `more_items:` drawer (Jogadores, Configurações, Perfil, Sair) |
| **Estados** | item ativo; drawer aberto/fechado; oculto em `≥sm` se sidebar existir |
| **Tokens** | fixo inferior; alvos ≥44pt; `pitch`/`cartola` no ativo |
| **Exemplo** | `render Ui::BottomNavComponent.new(items: [...], more_items: [...])` |
