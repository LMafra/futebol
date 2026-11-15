# TICKET-0109 — Classificação no Admin e no Gestor com dedução de pontos

- Deps: TICKET-0108
- Skill: [W]tdd
- MCP: playwright
- Origem: revisão do PR #87 (2026-11-14)

## Descrição
A Classificação só existia na página pública, e não havia como tirar pontos de um time (W.O., atleta irregular). O Admin e o Gestor não viam a tabela do campeonato que administram, e a tabela pública não tinha como explicar uma punição.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Visitante, Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`)

## Severidade
Média: faltava uma regra comum de campeonato amador, e a tabela pública não podia refletir uma punição.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/championships/2`.
2. Procurar a Classificação ou uma forma de deduzir pontos de um time.
3. Abrir `/campeonatos/2` e a home.

## Esperado
- Aba "Classificação" na página do campeonato, com o diálogo "Deduzir pontos" (Gestor só nos campeonatos dele).
- Coluna "Dedução", com pontos = V × 3 + E − dedução.
- Motivo visível na tabela pública e na home.

## Atual
A página do campeonato só tinha os dados, os times inscritos, as partidas e os bolões, sem classificação nem dedução (`docs/checkpoints/ux-audit/before-0109/`).

## Correção
- **`Core::PointDeduction`** (`core_point_deductions`):
  - campeonato, time inscrito, pontos inteiros > 0, motivo obrigatório (até 200 caracteres) e autor (`created_by`);
  - revogar marca `revoked_at` e `revoked_by`, sem apagar;
  - o banco também exige pontos > 0, motivo não vazio e revogação completa;
  - time e autores ficam sem `dependent` (registrado em `config/database_consistency.todo.yml`, como em `Cartola::ScoutEvent`), porque apagar um time ou um usuário não pode apagar o histórico de deduções.
- **`PointDeductions.deduct` / `.revoke`:** gravam um `Core::AuditLog` no campeonato na mesma transação (`championship.points_deducted`, `championship.points_deduction_revoked`).
- **`Simulador::StandingsCalculator`** recebe `deductions:` e continua sem banco. `Standing` ganhou `deduction` e `deduction_reasons`; pontos = V × 3 + E − dedução, e a ordem considera os pontos já deduzidos. O simulador também aplica as deduções.
- **`Core::ChampionshipStandingsService`:**
  - `table(championship)` monta a tabela da página pública, do Admin e do Gestor;
  - `top` traz os líderes da home e os times com dedução.
- **Aba "Classificação"** (`AdminChampionshipStandings`, compartilhado pelo Admin e pelo Gestor):
  - links "Dados" e "Classificação" (`?aba=classificacao`) na página do campeonato;
  - tabela com a coluna "Dedução" e o histórico de deduções (autor, data, revogação);
  - diálogo "Deduzir pontos" (time, pontos, motivo), que reabre com os erros;
  - "Revogar" com confirmação;
  - `deduct_points?` e `revoke_deduction?` seguem `update?`, então o Gestor só alcança os próprios campeonatos.
- **Público:**
  - a tabela tem sempre a coluna "Dedução";
  - `Ui::PointDeductionNotesComponent` lista, abaixo da tabela, "Time: −N pontos (motivo)";
  - na home, o líder com dedução mostra "−N" ao lado do nome, e o card lista o motivo de todo time com dedução, mesmo fora do top 4.
- **Glossário:** entrada "Dedução de pontos".

## Evidência
- Specs:
  - modelo (`spec/models/core/point_deduction_spec.rb`), calculador, serviço da classificação, componente da tabela e policy (`deduct_points?`, `revoke_deduction?`);
  - `spec/requests/point_deductions_spec.rb`: aba do Gestor; dedução com registro de auditoria; diálogo reaberto com erro; revogação mantida no histórico; Gestor de outro campeonato barrado; Admin; tabela pública; home; dedução revogada some.
- Navegador (`tmp/pw/deduct0109.js`, Gestor):
  - o diálogo abriu;
  - sem motivo, voltou com "Motivo não pode ficar em branco";
  - com motivo, "Ajax da Brasilândia perdeu 3 pontos";
  - a tabela pública e a home mostram "Ajax da Brasilândia: −3 pontos (W.O. na 3ª rodada)".
- Screenshots: `docs/checkpoints/ux-audit/before-0109/` e `after-0109/` (aba do Gestor e do Admin, diálogo, tabela pública e home).

## Pronto quando
- [x] `Core::PointDeduction` com motivo, autor, registro de auditoria e revogação sem apagar
- [x] `StandingsCalculator` com deduções e coluna "Dedução" (pontos = V × 3 + E − dedução)
- [x] Aba "Classificação" com "Deduzir pontos" no Admin e no Gestor (Gestor só nos campeonatos dele)
- [x] Tabela pública e home mostram a dedução com o motivo
