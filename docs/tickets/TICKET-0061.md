# TICKET-0061 — Gestor: scouts, finalizar e reverter partidas

- Deps: TICKET-0039, TICKET-0059, TICKET-0058
- Skill: [W]tdd
- MCP: —
- Spec: §9; [ADR 0005](../adr/0005-esquadrao-pontuacao-valorizacao.md)
- Estado anterior: scouts, finalização e reversão só no `/admin`; painel do gestor remetia à administração

## Escopo
- `Gestor::Core::MatchPolicy`: `record_scouts?`, `finalize?` e `revert?` = `admin? || manage?` (preview continua só admin)
- Páginas Pontuação (`MatchScouts`, `MatchFinalizer`, `MatchReversal`) registradas em `%i[admin gestor]` sem duplicar lógica
- `load_matches` usa `active_admin_authorization.scope_collection` para o seletor listar só partidas permitidas
- `AdminHelper#scoring_path` monta rotas por namespace; partials em `app/views/admin/match_*` compartilhados
- Link "Simular no Preview do Bolão" só no namespace `:admin`
- Painel e show de partida no `/gestor`: atalhos Scouts, Finalizar e Reverter; hints atualizados em `app/admin/gestor/matches.rb`

## Paths
- `app/policies/gestor/core/match_policy.rb`, `app/admin/{match_scouts,match_finalizer,match_reversal}.rb`
- `app/helpers/admin_helper.rb`, `app/views/admin/match_{scouts,finalizer,reversal}/*`
- `app/views/gestor/dashboard/_index.html.erb`, `app/admin/gestor/matches.rb`
- `spec/requests/gestor/scoring_spec.rb`, `spec/policies/gestor/core/match_policy_spec.rb`

## Pronto quando
- Gestor lança scouts, finaliza (enfileira `ProcessMatchPointsJob`) e reverte nas partidas dos próprios campeonatos em `/gestor`
- Partida de outro gestor → 403; gestor pendente → 403; admin pode usar `/gestor`
- Specs admin de scouts/finalizar/reverter continuam verdes

## Teste antes/depois
- Antes: `get /gestor/matchscouts` → 403 ou inexistente para gestor
- Depois: `spec/requests/gestor/scoring_spec.rb`; policy specs; specs admin existentes sem regressão
