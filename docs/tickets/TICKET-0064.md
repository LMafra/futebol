# TICKET-0064 — Layout ActiveAdmin (header / nav / footer)

- Deps: TICKET-0063
- Skill: [W]tdd
- MCP: —
- Spec: design 0001-critique Q5

## Escopo
- Partials AA4: `_site_header` (pitch + Fraunces), `_main_navigation` (paper + ativo cartola), `_site_footer` (GitHub)
- Layout `active_admin.html.erb` com `bg-paper`; fontes no `_html_head`; sem dark FOUC
- Spec `spec/requests/admin/layout_spec.rb`

## Paths
- `app/views/active_admin/_site_header.html.erb`
- `app/views/active_admin/_main_navigation.html.erb`
- `app/views/active_admin/_site_footer.html.erb`
- `app/views/active_admin/_html_head.html.erb`
- `app/views/layouts/active_admin.html.erb`
- `spec/requests/admin/layout_spec.rb`

## Pronto quando
- Header pitch + link home; nav paper/`border-rule`; footer GitHub
- Spec verde

## Teste antes/depois
- Antes: chrome Flowbite gray/dark
- Depois: chrome Craquefy editorial
