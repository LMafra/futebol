# TICKET-0086 — Mostrar senha nos campos de senha

- Deps: TICKET-0083
- Skill: [W]tdd
- MCP: —
- Origem: validação manual da leva 0079–0084 (2026-11-12)

## Descrição
Os campos de senha do login, do cadastro e da redefinição não deixam conferir o que foi digitado. No celular, o erro de digitação só aparece depois de enviar.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Visitante sem sessão

## Severidade
Baixa: não bloqueia, mas aumenta erros de login e cadastro, principalmente no celular.

## Passos para reproduzir
1. Abrir `/session/new` (ou `/cadastro`, ou o link de redefinir senha).
2. Digitar a senha.

## Esperado
Um botão "Mostrar senha" ao lado do campo alterna entre texto oculto e visível, e o leitor de tela anuncia o estado.

## Atual
Só existe o campo oculto.

## Correção
- `PasswordRevealHelper#password_reveal` envolve o campo com `data-controller="password-reveal"` e acrescenta um botão de 48px:
  - `type="button"`, `aria-label="Mostrar senha"` e `aria-pressed`;
  - ícone de olho que vira olho cortado com `group-aria-pressed`;
  - `hidden` até o Stimulus conectar, então sem JavaScript o campo continua um campo de senha comum.
- `password_reveal_controller.js` liga `aria-controls` ao id do campo e alterna `type` entre `password` e `text`.
- Aplicado em `sessions/new` (login público e áreas Admin/Gestor), `passwords/edit` (nova senha e confirmação) e `Ui::SignupFormComponent` (senha e confirmação). O campo ganha `pr-12` para o texto não passar por baixo do botão.

## Evidência
- Navegador (Playwright, 390px): botão visível 48×48, `aria-controls="password"`; clique → `type="text"` + `aria-pressed="true"`; segundo clique volta.
- `spec/helpers/password_reveal_helper_spec.rb`; `signup_form_component_spec`, `sessions_spec` e `passwords_spec` atualizados.

## Pronto quando
- Todos os campos de senha têm o botão
- Gate `test` verde
