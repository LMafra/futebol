# TICKET-0033 — Login em /entrar e menu da conta

- Deps: TICKET-0014, TICKET-0028
- Skill: [W]tdd
- MCP: —
- Spec: §8 (autenticação)
- Estado anterior: login só em `/session/new`; cabeçalho mostrava o e-mail do usuário; nenhum link para o admin

## Escopo
- `GET /entrar` (`login_path`) aponta para `sessions#new`; o redirect de autenticação continua em `/session/new`, e `/admin` anônimo continua indo para lá
- Cabeçalho: "Craquefy" à esquerda; "Entrar" para visitante; logado, menu `<details>` "Minha conta" (Minha conta, Meus bolões, Meu esquadrão, Rankings) e "Sair"
- Rodapé: "Acesso administrativo" para `/admin`
- Correção encontrada no caminho: o broadcast do placar renderizava o layout inteiro dentro do turbo-stream; passou a usar `layout: false`

## Paths
- `config/routes.rb`, `app/views/sessions/new.html.erb` (kicker da marca), `app/views/layouts/application.html.erb`, `app/services/broadcast_update_service.rb`

## Pronto quando
- `/entrar` responde 200 com o formulário de login
- O cabeçalho nunca mostra o e-mail; o menu da conta só aparece logado
- O rodapé tem o link do admin, e `/admin` sem sessão redireciona para `/session/new`

## Teste antes/depois
- Antes: `/entrar` → 404
- Depois: `spec/requests/sessions_spec.rb` (`/entrar` 200, menu logado, link do rodapé, `/admin` anônimo, redirect de `pools_path`); `spec/services/matches/broadcast_spec.rb` (stream sem layout)
