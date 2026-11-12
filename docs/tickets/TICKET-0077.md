# TICKET-0077 — Create campeonato: wizard só em `new`

- Deps: TICKET-0072, TICKET-0074
- Skill: [W]tdd
- MCP: —
- Spec: staged disclosure (Tidwell/Olsen) + dual mode

## Escopo
- Em **`new`** (Admin e Gestor): staged disclosure cosmético em 4 etapas (Dados → Esquadrão → Bolão → Premiação) com Stimulus (`form_wizard_controller.js`, pinado no importmap do AA).
  - Nav de etapas `1. Dados … 4. Premiação` com `aria-current="step"` e texto "Etapa N de 4" (`aria-live="polite"`); botões **Voltar** / **Continuar**; o envio (`fieldset.actions`) só aparece na última etapa.
  - Continua **um único POST**: os 4 fieldsets ficam no mesmo `<form>`, só alternando `hidden`. Enter num campo avança de etapa antes da última.
  - Erro de validação: o `new` re-renderizado abre na primeira etapa com `.error`/`.inline-errors`.
  - Sem JavaScript: nav e botões ficam `hidden` e todas as seções aparecem (progressive enhancement).
  - Defaults do model valem sem abrir nada; avançar não exige preencher Esquadrão/Bolão/Premiação.
- Em **`edit`**: página única com seções tituladas (comportamento do 0072), sem nav nem botões de etapa.
- Correção encontrada no caminho: checkbox/radio do Formtastic recebiam as classes de campo de texto (`w-full min-h-10`) e viravam uma caixa larga; agora usam `ADMIN_CHOICE_INPUT_CLASSES` (20px, `text-pitch`).
- Fora do escopo: resumo intermediário com o acumulado (opcional no plano; não entregue).

## Paths
- `app/admin/championships.rb`, `app/admin/gestor/championships.rb`
- `app/helpers/championship_wizard_helper.rb`
- `app/javascript/controllers/form_wizard_controller.js`, `app/javascript/admin.js`, `config/initializers/active_admin.rb`
- `config/initializers/formtastic_placar.rb`, `app/helpers/admin_helper.rb`
- `spec/requests/admin/championship_wizard_spec.rb`, `spec/requests/admin/form_spec.rb`

## Pronto quando
- `new` mostra progresso por etapas; `edit` permanece seções na mesma página
- Avançar com defaults não exige abrir “Mais opções”
- Gate `test` verde

## Teste antes/depois
- Antes: create e edit = mesma página longa em seções
- Depois: create = wizard; edit = seções (conferido no navegador: etapa 1 → Enter → etapa 2; envio só na etapa 4; POST inválido reabre em Dados; `edit` sem nav)
