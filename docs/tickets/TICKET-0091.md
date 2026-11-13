# TICKET-0091 — Escudo do time e logo do campeonato por upload

- Deps: TICKET-0090
- Skill: [W]tdd, migration
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 ([ADR 0006](../adr/0006-gestor-times-lances.md), Imagens)

## Descrição
- **Escudo por URL:** o escudo do time era uma URL digitada (`crest_url`). O gestor precisava hospedar a imagem em outro lugar, e um link quebrado só aparecia no placar ao vivo.
- **Sem logo:** o campeonato não tinha logo.
- **Pouca exibição:** a classificação e as páginas não mostravam imagem nenhuma.

## Ambiente
- Celular 390px, Chromium 1208 (Playwright), Rails 8.1 dev local (Active Storage em disco; R2 em produção)
- Gestor (`gestor@demo.local`)

## Severidade
Média: sem upload, os times e campeonatos amadores ficavam sem identidade visual.

## Passos para reproduzir
1. Entrar como gestor e editar um time em `/gestor/teams`.
2. Procurar onde enviar o escudo.

## Esperado
Campo de arquivo com prévia, limite de tipo e tamanho, e a imagem nas páginas.

## Atual
Só um campo de texto "URL do escudo".

## Correção
- **`Core::ImageAttachment`:**
  - `image_attachment :crest` no time e `:logo` no campeonato;
  - aceita PNG, JPEG, WebP ou SVG de até 2 MB;
  - variantes `thumb` (64px) e `medium` (256px);
  - `remove_<nome>` para a caixa "Remover".
- **Formulários** (Admin e Gestor, via `AdminImageInput`):
  - `accept` com os tipos;
  - a imagem atual na dica;
  - prévia do arquivo escolhido e aviso acima de 2 MB antes do envio (`image_preview_controller.js`);
  - "Remover escudo"/"Remover logo" quando já há imagem.
- **Exibição** (`ImagesHelper`):
  - escudo no placar ao vivo e na classificação pública, com a sigla quando não há escudo;
  - logo no cabeçalho do campeonato e nos cards da home;
  - escudo e logo nas páginas do Admin e do Gestor.
  - As variantes dependem da libvips, que está na imagem Docker. Sem ela, como no ambiente local e no CI, e para SVG, a imagem original é exibida e redimensionada por CSS.
  - As consultas da classificação e do Simulador carregam os escudos junto (`Core::Match.with_team_crests`), sem N+1.
- **Migrações:**
  - `ImportTeamCrestUrls` baixa cada `crest_url`, com timeout de 5 s e só imagens de até 2 MB, e anexa como escudo. Falhas vão para o log, e o time fica com a sigla.
  - `RemoveCrestUrlFromCoreTeams` remove a coluna.

## Evidência
- `spec/models/core/image_attachment_spec.rb`, `spec/data_migrations/crest_url_import_spec.rb`, `spec/requests/gestor/images_spec.rb`
- Playwright 390px: prévia do escudo no formulário do time; logo no cabeçalho de `/campeonatos/2`; escudo na classificação

## Pronto quando
- [x] Upload de escudo e logo com prévia, tipo e tamanho validados
- [x] Imagem no placar, na classificação, no cabeçalho do campeonato e na home
- [x] `crest_url` migrado (best effort) e removido
