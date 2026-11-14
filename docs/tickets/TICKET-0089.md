# TICKET-0089 — ADR 0006 e glossário: times do gestor, inscrição, modalidade, rascunho e lances

- Deps: TICKET-0085
- Skill: domain-modeling
- MCP: —
- Origem: rodada de ajustes de 2026-11-12, com as decisões do grill ("um gestor tem N campeonatos; um campeonato tem N times e N partidas; os times e jogadores pertencem àquele gestor")

## Descrição
A fase de modelo (0090–0093) muda quem é dono dos times, como as partidas escolhem os times, de onde vêm os scouts e quem cria bolões. Nenhuma dessas regras estava registrada. O glossário não tinha nome para o vínculo entre time e campeonato, para o contato do time, para o scout com minuto, para o formato do campeonato nem para o campeonato não publicado.

## Ambiente
- Documentação (`docs/adr`, `docs/glossary.md`); sem código

## Severidade
Média: sem o registro, os tickets 0090–0096 decidiriam o modelo um a um, com nomes diferentes para a mesma coisa.

## Passos para reproduzir
1. Procurar em `docs/adr/` a regra de posse dos times ou dos lances com minuto.
2. Procurar "Inscrição", "Capitão", "Lance", "Modalidade" ou "Rascunho" em `docs/glossary.md`.

## Esperado
Um ADR com as decisões e as alternativas, e os termos no glossário.

## Atual
Nenhum dos dois existia.

## Correção
- [ADR 0006](../adr/0006-gestor-times-lances.md), arquivo novo, sem alterar os ADRs 0001–0005:
  - times do gestor (`manager_id`) e inscrição em campeonatos, com a migração por duplicação dos times compartilhados entre gestores;
  - partida só com times inscritos;
  - capitão como contato;
  - modalidade em quatro campos e campeonato em rascunho até a Revisão;
  - escudo e logo via Active Storage;
  - lances (`Cartola::ScoutEvent`) com minuto e tempo, dos quais o `PlayerScore` é derivado;
  - bolão criado só por Gestor e Admin, com correções com motivo.
  - Alternativas comparadas para a posse dos times e para a origem dos scouts.
- [Glossário](../glossary.md):
  - termos novos: Time do gestor, Inscrição, Capitão (diferente do capitão da escalação), Lance, Modalidade e Rascunho;
  - Scout e Pool atualizados.
- Tickets da fase, na ordem: 0090 (time do gestor, inscrição, capitão), 0091 (imagens), 0092 (modalidade, rascunho, assistente), 0093 (bolão só Gestor/Admin).

## Evidência
- `docs/adr/0006-gestor-times-lances.md`
- `docs/glossary.md`

## Pronto quando
- [x] ADR 0006 com problema, decisão, alternativas e consequências
- [x] Glossário com Inscrição, Capitão, Lance, Modalidade e Rascunho
- [x] ADRs existentes, `docs/spec-v2.md` e `docs/design/*` sem alteração
