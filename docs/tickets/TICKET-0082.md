# TICKET-0082 — Base visual pública: CSS do Admin vazando, classes fora da escala, campos e foco

- Deps: TICKET-0080
- Skill: [W]tdd, ui-ux-pro-max
- MCP: —
- Origem: auditoria UI/UX completa (2026-11-12)

## Descrição
O layout público usava `stylesheet_link_tag :app`. Com Propshaft, isso carrega todo CSS de `app/assets`, inclusive o build do ActiveAdmin. Dois efeitos:
- As regras do Admin valiam nas telas públicas.
- As classes fora da escala de espaçamento pública (0 1 2 3 4 6 8 12 16 em `config/tailwind.config.js`) só funcionavam por causa do vazamento: `h-10`, `w-14`, `h-96`, `min-w-28`, `w-32`, `w-40`, `w-48`, `h-5`, `h-7`, `h-9`.

Além disso:
- Os campos públicos tinham borda `rule` (cerca de 1,3:1 sobre `paper`) e alturas de 28–36px.
- O "AO VIVO" do simulador era texto `cartola` (cerca de 3:1).
- A formação e as vagas no campo do Esquadrão usavam `text-rule` sobre `pitch` (cerca de 4,4:1).
- Não havia anel de foco comum.
- Vários alvos de toque tinham menos de 40px: setas de "Jogos de hoje", controles do header, "Copiar chave", palpite e capitão.

## Ambiente
- Desktop 1440px e mobile 390px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Usuários: visitante e `demo1@demo.local`

## Severidade
Alta: a aparência pública dependia de um CSS que não era dela. Quebrar o vazamento sem remapear as classes colapsaria skeletons, o campo do Esquadrão e os palpites.

## Passos para reproduzir
1. Abrir `/` e inspecionar os `<link rel="stylesheet">`: aparece `active_admin-*.css`.
2. Procurar `.h-10` em `app/assets/builds/tailwind.css`: não existe.
3. Abrir `/simulador/<id>` com jogo ao vivo e `/lineup/edit` em 390px.

## Esperado
- O público carrega só `tailwind` e `application`.
- Toda classe usada no público existe no build público.
- Campos brancos com borda `graphite`, 48px de altura e foco visível.
- Chip "AO VIVO" legível.

## Atual
- O CSS do Admin é carregado.
- As classes só existem no build do Admin.
- Campos com borda quase invisível.
- "AO VIVO" laranja sobre fundo claro.

## Correção
- [app/views/layouts/application.html.erb](../../app/views/layouts/application.html.erb): `stylesheet_link_tag "tailwind", "application"`. O layout do Admin já usa `active_admin`.
- **Classes remapeadas para a escala:**
  - skeletons `h-10` → `h-12` (bets, formação, bolões, cadastro); `h-7` → `h-8`; `h-5` → `h-6`; `h-96` → `h-[24rem]`
  - palpite `h-9 w-14` → `h-12 w-16`
  - `min-w-28` → `min-w-[7rem]`; `w-32` → `w-[8rem]`; `w-40` → `w-[10rem]`; menu da conta `w-48` → `w-max min-w-[12rem]`
  - tabela do leaderboard: `w-10` → `w-12`; `font-body` → `font-sans`
- **`FormControlHelper#form_control_classes`** (`bg-white border-graphite min-h-12`, foco `outline-2 outline-pitch`, variante `invalid:` com `border-2 border-ink`). Vale em entrar, recuperar/redefinir senha, cadastro, palpite, novo bolão, entrar com código, simulador, filtro de rankings e seletor de posição. `Ui::BaseComponent` inclui o helper.
- **"AO VIVO"** vira chip `bg-cartola text-ink`, fora do nome truncado. No campo do Esquadrão, o texto sobre `pitch` passa para `text-white`.
- **Foco global** em `@layer base`: `:focus-visible` com `outline-2 outline-offset-2 outline-ink`; dentro de header, `bg-pitch` e `bg-night`, `outline-white`.
- **Alvos de toque de 48px:**
  - setas de "Jogos de hoje" (`size-12`) e da rodada no simulador
  - marca, "Minha conta", itens do menu, "Sair", "Entrar" e "Copiar chave"
  - inputs do simulador e botão "Palpitar"
  - select e "Ver" dos rankings
  - capitão como chip `size-12` sobre radio nativo `sr-only peer` (padrão do seletor de formação)
  - checkboxes do seletor de jogadores com `accent-pitch`
- Toast, StatusBadge, EmptyState, FormSection, AdminTable, PreviewPanel e CsvImportStatus só aparecem no Admin, cujo build usa a escala padrão do Tailwind. Por isso ficam fora da regra.

## Evidência
- Navegador (Playwright), 1440px e 390px:
  - home, campeonato, bolões, palpites, Esquadrão, escalação, rankings, simulador, conta, entrar e cadastro respondem 200.
  - O probe de contraste caiu em palpites (19 → 18) e no bolão (3 → 1). O que sobra são falsos positivos dos tints de 15% `win`/`loss`, que o probe lê como cor sólida.
- `spec/design/public_visual_base_spec.rb`: lista de padrões fora da escala, `font-body` proibido, foco global e helper de campo.
- `spec/requests/public_layout_spec.rb`; specs dos componentes de palpite, seletor de jogadores e campo; `simulador_spec` (chip e 48px).

## Pronto quando
- O layout público não inclui `active_admin`
- Nenhuma classe fora da escala nos templates públicos
- Gate `test` verde
