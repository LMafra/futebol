# TICKET-0008 — (h) BroadcastUpdateService (unless_exist + concorrência)

- Deps: TICKET-0004
- Skill: [W]tdd
- MCP: —
- Spec: §7

## Paths
- `app/services/broadcast_update_service.rb`
- `spec/services/broadcast_update_service_spec.rb`

## Pronto quando
- `Rails.cache.write("broadcast:match:#{id}", 1, unless_exist: true, expires_in: 5.seconds)`; só quem grava faz `Turbo::StreamsChannel.broadcast_replace_to`
- Cache store de teste suporta `unless_exist` (memory_store/solid_cache)

## Teste antes/depois
- Antes: 10 chamadas concorrentes → 10 broadcasts
- Depois: spec de concorrência com 10 `Thread`s + `Concurrent::CountDownLatch` → exatamente 1 broadcast (`have_broadcasted_to(...).once`)
