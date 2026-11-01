# AGENTS.md

## Cursor Cloud specific instructions

- Um ticket por branch. Commit assinado. PR ao final de cada tier.
- Rodar o comando `test` de `.cursor/environment.json` após cada ticket.
- Ticket com 2 falhas → marcar `blocked` no checkpoint, pular, continuar o tier.
- ≥50% do tier falhou → parar, escrever `docs/checkpoints/TIER-N.yaml` com `status: failed`.
- Nunca alterar `docs/spec-v2.md`, `docs/adr/*`, `docs/design/*`.
- Atualizar `docs/checkpoints/STATUS.md` ao fim de cada tier.
