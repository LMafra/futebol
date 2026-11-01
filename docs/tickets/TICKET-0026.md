# TICKET-0026 — Simulador: definir escopo (ADR)

- Deps: —
- Skill: to-spec (indisponível localmente → escrita manual, como na PHASE-3), [W]grilling (grill-me) obrigatório antes do merge
- MCP: —
- Spec: título "Bolão · Cartola · Simulador" (Simulador sem contrato na §1–§9); ADR 0001 §1 (engine `simulador` existe vazia)

## Paths
- `docs/adr/0003-simulador.md` (arquivo novo)

## Bloqueios conhecidos (resolver antes de começar)
- AGENTS.md: "Nunca alterar `docs/adr/*`". Este ticket só cria `0003-simulador.md`; `0001-arch.md` e `0002-activeadmin-rails81.md` ficam intactos. Confirmar com o usuário que criar um ADR novo é permitido.

## Pronto quando
- ADR com 9 seções: 1 problema, 2 fluxo do usuário, 3 modelo de dados, 4 output, 5 gratuidade (o que é grátis para o usuário), 6 free tier (Render/Neon: CPU, jobs, storage), 7 alternativas (exatamente 3), 8 decisão, 9 tickets derivados
- Decisão escolhe 1 das 3 alternativas, com justificativa ligada às seções 5 e 6
- Tickets derivados listados com título e deps (sem criar os arquivos aqui)
- Sessão grill registrada no ADR ou no PR com ≥3 objeções e a resposta de cada uma

## Teste antes/depois
- Antes: `docs/adr/0003-simulador.md` inexistente; engine `simulador` só com `application_*`
- Depois: `test -f docs/adr/0003-simulador.md`; `rg -c '^## ' docs/adr/0003-simulador.md` = 9; a seção "Decisão" cita 1 das 3 alternativas da seção 7; "Tickets derivados" tem ≥1 item; 3 objeções do grill respondidas; `git diff --stat` não toca `0001`/`0002`
