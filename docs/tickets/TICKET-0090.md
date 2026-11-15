# TICKET-0090 — Time do gestor, inscrição em campeonatos e capitão

- Deps: TICKET-0089 (ADR 0006)
- Skill: [W]tdd, migration
- MCP: —
- Origem: rodada de ajustes de 2026-11-12: "um gestor tem N campeonatos; um campeonato tem N times e N partidas; os times e jogadores pertencem àquele gestor"

## Descrição
Os times eram globais:
- **Vínculo deduzido:** o campeonato de um time vinha das partidas (`Core::Team#championships`, `Core::Championship#teams`).
- **Times alheios visíveis:** em `/gestor/teams`, o gestor via os próprios times, os times sem partida de qualquer gestor e, travados para edição, os que jogavam em campeonatos alheios.
- **Partida sem checagem de vínculo:** aceitava qualquer par de times, de qualquer gestor.
- **Sem capitão:** não havia contato do time.

## Ambiente
- Desktop 1440px e celular 390px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Gestor (`gestor@demo.local`) e admin (`admin@futebol.dev`)

## Severidade
Alta: um gestor via e escalava times de outro gestor, e uma partida podia juntar times que não participavam do campeonato.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/teams`.
2. Abrir `/gestor/matches/new` e escolher o mandante.

## Esperado
O gestor vê e edita só os próprios times. A partida oferece só os times inscritos no campeonato.

## Atual
A lista mostrava times de outros gestores (travados) e a partida aceitava qualquer time visível.

## Correção
- **Modelo** ([ADR 0006](../adr/0006-gestor-times-lances.md)):
  - `core_teams.manager_id` (nulo = Admin), com a sigla única por gestor (`NULLS NOT DISTINCT`);
  - `core_championship_teams` (Inscrição), que só aceita time do mesmo gestor do campeonato e não sai enquanto o time tiver partidas nele;
  - `Core::Match` valida que mandante e visitante estão inscritos quando a partida é criada ou os times mudam;
  - o time não troca de gestor enquanto tiver inscrições.
- **Capitão:** `captain_name` e `captain_phone`. O telefone é normalizado para DDD + número (aceita "+55 (11) 98765-4321") e validado como celular ou fixo; aparece como "(11) 98765-4321".
- **Migração** (`DataMigrations::TeamOwnership`, com `down`):
  - o time fica com o gestor em que tem mais partidas;
  - cada outro gestor (ou o Admin) ganha uma cópia com os jogadores, e as partidas, scouts, valores e escalações daquele gestor passam para a cópia;
  - as inscrições vêm das partidas;
  - o `down` junta as cópias de volta pelo sufixo do `external_id`.
- **Policies:** `Core::TeamPolicy` e o escopo dos jogadores passam a usar `manager_id`. Sai o "time travado" (`locked_ids`, `gestor_team_editable?`). Jogador só é criado em time próprio.
- **Telas:**
  - página do campeonato (Admin e Gestor): painel "Times inscritos" com "Inscrever time", "Remover {time}" (ou "Tem partidas") e o capitão;
  - "Nova partida" na página do campeonato do Gestor, com o campeonato já escolhido;
  - nova partida: mandante e visitante só entre os inscritos (agrupados por campeonato enquanto nenhum é escolhido);
  - time: seção Capitão, linha "Campeonatos" e, no Admin, o campo Gestor com o filtro.
- **Seeds:** os times são inscritos antes das partidas, e o gestor demo recebe os times do campeonato que assume.

## Evidência
- `spec/lib/data_migrations/team_ownership_spec.rb` (time em dois gestores, Admin, `down`)
- `spec/models/core/{team,match,championship_team}_spec.rb`
- `spec/requests/gestor/teams_and_enrollments_spec.rb`
- Migração aplicada, desfeita e reaplicada no banco de desenvolvimento: 62 times, 62 inscrições, 6 times do gestor demo

## Pronto quando
- [x] Gestor vê e edita só os próprios times e jogadores
- [x] Inscrição pela página do campeonato, com bloqueio para time alheio e para time com partidas
- [x] Partida só com times inscritos
- [x] Capitão com telefone BR validado
- [x] Migração com duplicação e `down`, com spec
