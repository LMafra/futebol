# TICKET-0077 — Create campeonato: wizard só em `new`

- Deps: TICKET-0072, TICKET-0074
- Skill: [W]tdd
- MCP: —
- Spec: staged disclosure (Tidwell/Olsen) + dual mode

## Escopo
- Em **`new`**: staged disclosure em 4 passos (Dados → Esquadrão → Bolão → Premiação) com indicador de progresso e defaults inteligentes
- Em **`edit`**: manter página única com seções tituladas (comportamento atual do 0072)
- Resumo intermediário opcional (sidebar ou topo) com o acumulado já configurado
- Não forçar wizard em gestores experientes na edição; create inicial guia o novato

## Paths
- `app/views/admin/championships/` e/ou `app/views/gestor/championships/`
- partials de FormSection existentes
- `spec/requests/**/championships*_spec.rb` (new vs edit)

## Pronto quando
- `new` mostra progresso por etapas; `edit` permanece seções na mesma página
- Avançar com defaults não exige abrir “Mais opções”
- Gate `test` verde

## Teste antes/depois
- Antes: create e edit = mesma página longa em seções
- Depois: create = wizard; edit = seções
