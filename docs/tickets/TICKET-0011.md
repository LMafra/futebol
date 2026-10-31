# TICKET-0011 — (k) Design system: tailwind tokens + ViewComponents 4 estados

- Deps: TICKET-0001
- Skill: [N]ui-ux-pro-max, [N]design-system, [W]grilling (grill-me) obrigatório antes do merge
- MCP: —
- Spec: §4, §5; design `docs/design/0001-direction.md` + `0001-critique.md`

## Paths
- `config/tailwind.config.js`, `app/assets/tailwind/application.css`
- `app/components/{scoreboard,standings_table,prediction_form,preview_panel,csv_import_status}_component.{rb,html.erb}`
- `spec/components/*_spec.rb`, `spec/components/previews/*_preview.rb`

## Pronto quando
- 5 componentes × `default|loading|empty|error`; estado inválido → ArgumentError
- win/draw/loss tint + glifo; Fraunces ≥ text-xl; `tabular-nums`
- CI grep anti-AI (sem `bg-gradient`, `backdrop-blur`, sombras coloridas)
- Sessão grill registrada no PR

## Teste antes/depois
- Antes: componente renderiza só default; sem previews
- Depois: spec por estado (`render_inline(..., state:)` + seletor esperado); 20 previews Lookbook; grep anti-AI exit 0
