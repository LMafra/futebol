# TICKET-0032 — Home pública e flag privado em campeonatos

- Deps: TICKET-0011, TICKET-0031, TICKET-0035, TICKET-0038
- Skill: [W]tdd
- MCP: mobbin (indisponível: exige plano pago)
- Spec: §10 (Simulador); [ADR 0005](../adr/0005-esquadrao-pontuacao-valorizacao.md) (ranking de atletas)
- Estado anterior: `root 'home#index'` existia, mas o `require_authentication` mandava visitantes para o login; campeonatos não tinham como ficar fora da área pública

## Escopo
- Flag `core_championships.private` (default `false`): campeonatos privados ficam fora da home, da página pública (TICKET-0035) e do Simulador para visitantes; um campeonato privado pedido por id dá 404
- Home sem login (`allow_unauthenticated_access`), com seções editoriais: hero, faixa-placar com contadores, módulos em grid 8/4 com ícones Lucide em SVG inline, jogos de hoje, grid de campeonatos com Top 3 do Bolão e do Esquadrão e "Ver ranking completo", top 10 de atletas (J, G, A, Pts), "Como funciona" e rodapé com ©, GitHub, documentação e licença
- "Entrar" do hero é o único acento laranja da página; "Criar conta" em outline; quem está logado vê atalhos para Meus bolões, Meu esquadrão e Simulador
- Fora do escopo: referências do Mobbin (a API respondeu "requires a paid plan"; a hierarquia segue o design system)

## Paths
- Bloco A: `engines/core/db/migrate/20261031000037_add_private_to_core_championships.rb`, `engines/core/app/models/core/championship.rb` (scopes `publicly_visible` e `private_only`, ransack), `app/admin/championships.rb` ("Campeonato privado?"), `db/seeds/championships.rb`, `app/controllers/simulador/simulations_controller.rb`
- Bloco E: `app/controllers/home_controller.rb`, `app/services/cartola/top_players_service.rb`, `app/views/home/{index,_hero,_counters,_modules,_matches_today,_championships,_top_players,_how_it_works}.html.erb`, `app/views/layouts/application.html.erb` (rodapé)

## Pronto quando
- `/` responde 200 sem sessão e lista só campeonatos públicos, com contadores, Top 3 de cada ranking e link para `/campeonatos/:id?tab=bolao`
- Nenhum e-mail aparece no HTML; nomes seguem o consentimento (TICKET-0038)
- Todas as listas saem de queries agrupadas: contadores, jogos de hoje com `includes` dos times, rankings em lote, times e status por campeonato em 2 queries, atletas com `preload(player: :team)`
- Visitante não vê campeonato privado no Simulador (404 por id)

## Teste antes/depois
- Antes: `/` sem sessão → 302 para `/session/new`
- Depois: `spec/requests/home_spec.rb` (200 público, seções, hero de visitante e de logado, campeonatos privados fora, Top 3, atletas, sem e-mail, sem N+1 pelo Prosopite); `spec/models/core/championship_spec.rb` (scopes); `spec/requests/admin/cartola_settings_spec.rb` (admin salva a flag); `spec/requests/simulador_spec.rb` (privado 404)
