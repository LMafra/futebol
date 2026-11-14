# TICKET-0080 — Base visual do Admin/Gestor: campos invisíveis, links fora de camada e dark mode acidental

- Deps: TICKET-0063, TICKET-0079
- Skill: [W]tdd, ui-ux-pro-max
- MCP: —
- Origem: auditoria UI/UX completa (2026-11-12)

## Descrição
Os campos do Admin e do Gestor tinham fundo `paper` sobre superfícies `paper`, com borda `rule` (1,32:1). Na prática, ficavam invisíveis. O `active_admin.css` tinha uma regra `a { … }` fora de qualquer `@layer`, que vencia todas as utilities: links com `text-paper`/`no-underline` (marca no header, menu do usuário) herdavam pitch sublinhado. O `dark_mode_toggle.js` do ActiveAdmin aplicava `.dark` quando o sistema operacional preferia o modo escuro, e as variantes `dark:` do plugin repintavam o Admin, que é só claro. `cartola` era usado como cor de texto (badge “Ao vivo”, item ativo do menu, hovers, toast de alerta), com cerca de 3:1 sobre `paper`.

## Ambiente
- Desktop 1440px e mobile 390px, Chromium 1208 (Playwright), `prefers-color-scheme` light e dark
- Rails 8.1 dev local, ActiveAdmin 4.0.0.beta23, Tailwind v4
- Usuários: admin (`admin@futebol.dev`) e gestor (`gestor@demo.local`)

## Severidade
Alta — formulários de todas as telas do Admin e do Gestor sem limite visível de campo; com o sistema em modo escuro, o Admin trocava de tema.

## Passos para reproduzir
1. Entrar como admin com o sistema operacional em modo escuro.
2. Abrir `/admin/championships/new`.
3. Observar os campos e o `<html class="dark">`.

## Esperado
Admin sempre claro; campos brancos com borda `graphite` e foco `ink` visível; nenhum texto em `cartola`.

## Atual
Campos `paper` sobre `paper` (borda 1,32:1); tema escuro parcial; links da marca e do menu sublinhados em pitch.

## Correção
- `active_admin.css`: removida a regra de link fora de camada. A base de link, foco e campos foi movida para `@layer base` com prefixo `:root`. O plugin emite a própria base depois, na mesma camada; o prefixo ganha por especificidade e continua abaixo das utilities.
- Campos (`input`, `select`, `textarea`, `file`, `checkbox`/`radio`): `bg-white`, `border-graphite/70` e foco `ink`. Formtastic: fieldset branco, erros `ink` sobre `loss`.
- `tailwind-active_admin.config.js`: `darkMode` aponta para `[data-theme=never]`; `admin.js` grava `theme=light` antes do `DOMContentLoaded`.
- `config/initializers/active_admin.rb`: o importmap do Admin ganha cache sweeper em dev. Sem ele, editar `admin.js` dava 404 no digest até reiniciar o servidor.
- `AdminHelper`: papéis de botão (primário `cartola`/`ink`, secundário branco/`graphite`, perigo `loss-solid`/`paper`), todos com `min-h-10` e anel de foco `ink`. Campos com `min-h-10`.
- `StatusBadge` “Ao vivo”: `bg-cartola text-ink`. Toast de alerta: `role="alert"`, texto `ink`.
- Menu lateral: item ativo `cartola/15` + barra `cartola` + texto `ink` semibold. Hovers em `cartola` trocados por sublinhado ou borda `ink` nos dashboards, breadcrumb, rodapé, comentários e paginação.
- Superfícies dos dashboards e `FormSection`: `bg-white` sobre a página `paper`.

## Evidência
- Antes: `docs/checkpoints/ux-audit/before/admin-championship-new-1440-dark.png`, `before/probe.json` (`dark=true`; campos com `bg` igual ao entorno)
- Depois: `probe.json` com `dark=false` nos 6 cenários dark; campos brancos com borda 20,99:1 contra o entorno branco

## Pronto quando
- Admin claro com qualquer preferência do sistema operacional
- Nenhum `text-cartola` em `app/views/{active_admin,admin,gestor}` nem no `active_admin.css`
- `spec/design/admin_visual_base_spec.rb` verde
- Gate `test` verde
