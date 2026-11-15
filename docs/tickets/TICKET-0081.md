# TICKET-0081 — Acessibilidade dos componentes do Admin: abas de scouts, menu, alvos de toque e mobile

- Deps: TICKET-0080
- Skill: [W]tdd, ui-ux-pro-max
- MCP: —
- Origem: auditoria UI/UX completa (2026-11-12)

## Descrição
Os componentes do Admin falhavam em critérios WCAG 2.2 AA básicos:
- **Abas Mandante/Visitante:** as duas usavam o mesmo botão primário (o estado selecionado não era visível), sem `aria-controls`, `role="tabpanel"` nem navegação por setas.
- **Botões −/+ dos scouts:** cerca de 20px, com `aria-label` "menos"/"mais" iguais em toda a tabela.
- **Menu lateral:** os toggles não expunham `aria-expanded`, o item ativo não tinha `aria-current` e o `aria-label="Ativar seção"` substituía o nome da seção.
- **Paginação e ações de linha:** 32px, e a página atual não tinha `aria-current`.
- **Busca sem resultado:** mostrava o bloco cinza/dark do ActiveAdmin.
- **Flash:** o container ficava sempre renderizado, e o `aria-label="Aviso"` escondia a mensagem dos leitores de tela.
- **KPIs do dashboard:** o acento de cor brigava com `border-rule`.
- **Mobile:** a barra de filtros ocupava a primeira tela inteira.

## Ambiente
- Desktop 1440px e mobile 390px, Chromium 1208 (Playwright), Rails 8.1 dev local, ActiveAdmin 4.0.0.beta23
- Usuário: admin (`admin@futebol.dev`)

## Severidade
Média: navegação por teclado e leitor de tela degradada nas telas de operação (scouts, listas), mas sem bloqueio total.

## Passos para reproduzir
1. Abrir `/admin/matchscouts?match_id=<partida ao vivo>`.
2. Focar a aba "Mandante" e pressionar seta para a direita.
3. Abrir `/admin/championships?q[name_cont]=inexistente`.
4. Abrir `/admin/matches` em 390px.

## Esperado
- A seta troca a aba, e o selecionado fica visível.
- Os botões −/+ têm 40px e um rótulo como "Aumentar G de Fulano".
- A busca vazia mostra o estado vazio da marca com "Limpar filtros".
- Em 390px, os filtros ficam recolhidos.

## Atual
- A seta não faz nada e as abas são idênticas.
- Os botões têm 20px e o rótulo "mais".
- A busca vazia mostra o bloco cinza do ActiveAdmin.
- Em 390px, os filtros ocupam a tela.

## Correção
- Abas de scouts:
  - `ADMIN_TAB_CLASSES`: selecionada `cartola`, não selecionada branca/`graphite`, via `aria-[selected]`.
  - `aria-controls` + `tabpanel` + `tabindex` rotativo.
  - `scouts#navigate` com Setas, Home e End.
- Steppers: `ADMIN_STEPPER_CLASSES` (40px, estado desabilitado) com `aria-label` "Diminuir/Aumentar {scout} de {jogador}".
- Menu lateral:
  - `aria-current="page"` no item ativo.
  - Toggles `<button type="button">` com `aria-expanded` e `aria-controls`, sincronizados em `admin.js`.
  - O toggle sem texto recebe o rótulo "Expandir ou recolher {seção}".
  - Links com 40px.
- Busca vazia: `_index_empty_results` com `Ui::EmptyStateComponent` e "Limpar filtros".
- Paginação: `min-h-10 min-w-10` e `aria-current="page"`. Ações de linha com 40px; excluir com hover `loss`.
- Flash:
  - O container só existe com mensagens.
  - Toast sem `aria-label` no estado padrão.
  - Botão "Fechar aviso" de 40px (`dismiss_controller.js`).
- Mobile:
  - Filtros em `<details>`, recolhidos abaixo de `md` salvo com filtro ativo.
  - `.attributes-table` com `overflow-x-auto` e `overflow-wrap:anywhere`.
  - `pre` com quebra.
- KPIs: `border-l-pitch|cartola|ink|graphite`.
- Campos desabilitados com fundo `rule/40` e texto `graphite`.

## Evidência
- Navegador (Playwright): seta → foco e `aria-selected` na aba Visitante, painel Mandante oculto; toggle do menu `aria-expanded` false → true; filtros em 390px fechados, abertos com `q[...]`.
- `spec/requests/admin/accessibility_spec.rb`, `spec/components/ui/toast_component_spec.rb`

## Pronto quando
- Specs de acessibilidade verdes
- Gate `test` verde
