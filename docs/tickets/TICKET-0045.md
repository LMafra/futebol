# TICKET-0045 — Fuso do app em Brasília

- Deps: TICKET-0042
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: `config.time_zone` não estava definido, então o app rodava em UTC. "Jogos de hoje" virava o dia às 21h de Brasília, os horários apareciam 3 horas adiantados (um jogo das 16:00 de Brasília aparecia como 19:00) e o CSV de partidas lia `match_date` como UTC

## Escopo
- `config.time_zone = 'Brasilia'` (America/Sao_Paulo) em `config/application.rb`. O banco continua em UTC (`active_record.default_timezone` padrão); muda só a interpretação e a exibição
- Efeitos: `Date.current` ("Jogos de hoje", ano do rodapé) segue o dia de Brasília; `l(match.match_date)` mostra o horário de Brasília; `Time.zone.parse` no CSV de partidas lê `2026-04-12 16:00` como 16:00 de Brasília, a mesma convenção do seed
- Produção: partidas do seed já usavam o fuso de São Paulo explicitamente e passam a aparecer no horário certo. Partidas importadas por CSV antes desta mudança foram lidas como UTC e ficam 3 horas antes do pretendido; se houver alguma, reimportar ou corrigir no admin
- Agendamentos do Solid Queue (`config/recurring.yml`) não dependem do fuso (só "every hour at minute 12")

## Paths
- `config/application.rb`

## Pronto quando
- Às 22h de Brasília, um jogo das 21h de Brasília ainda aparece em "Jogos de hoje"

## Teste antes/depois
- Antes: o filtro de "hoje" usava o dia UTC
- Depois: `spec/requests/home_spec.rb` (às 22:30 de Brasília de 1/11, mostra o jogo das 21:00 de 1/11 e não o das 10:00 de 2/11)
