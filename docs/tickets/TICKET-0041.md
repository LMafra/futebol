# TICKET-0041 — Simulador por campeonato e rodapé com autor e Pix

- Deps: TICKET-0031, TICKET-0032, TICKET-0035
- Skill: [W]tdd
- MCP: —
- Spec: §10 (Simulador); [ADR 0003](../adr/0003-simulador.md)
- Estado anterior: `/simulador` abria direto o campeonato mais recente, com um seletor no cabeçalho; os jogos em aberto apareciam com todas as rodadas empilhadas; o rodapé não tinha autor nem forma de apoio

## Escopo
- O Simulador é de um campeonato: `GET /simulador` (`simulations#index`) lista os campeonatos para escolher, e cada um abre em `/simulador/:championship_id`, sem login
- Visitante vê só campeonatos públicos; usuário logado vê todos (`Simulador::SimulationPolicy::Scope`, também usado no `show` e no `preview`); sem campeonato ou com campeonato fora do escopo → 404, inclusive em `POST /simulador/projecao` sem `championship_id`
- A página pública do campeonato ganha o botão "Simular"; o simulador tem "Ver campeonato" (só para públicos) e "Outros campeonatos"
- Jogos em aberto: uma rodada por vez, com botões "Anterior" e "Próxima" e o rótulo "Rodada N · i de total" (Stimulus `rounds_controller`). As rodadas ocultas continuam no formulário, então todos os palpites são enviados; sem JS, as rodadas ficam empilhadas. Depois de projetar, o carrossel volta à rodada em que o visitante estava (`round_index`) ou à primeira com erro
- Rodapé: "Desenvolvido por LMafra" com link para `https://github.com/LMafra` e "Pague o Café" com a chave Pix e botão "Copiar chave" (Stimulus `clipboard_controller`); autor, link e chave em `brand.*` no `config/locales/pt-BR.yml`
- Divergência do ADR 0003: o ADR descreve `GET /simulador` abrindo o simulador; agora é a lista de campeonatos. O ADR não foi editado

## Paths
- `config/routes.rb`, `app/controllers/simulador/simulations_controller.rb`, `app/policies/simulador/simulation_policy.rb`, `app/helpers/simulador_helper.rb`
- `app/views/simulador/simulations/{index,show,preview,_simulator}.html.erb`, `app/views/championships/show.html.erb`
- `app/javascript/controllers/{rounds,clipboard}_controller.js`
- `app/views/layouts/application.html.erb`, `config/locales/pt-BR.yml`

## Pronto quando
- `/simulador` lista os campeonatos (privados só para quem está logado) e nenhum abre sozinho
- O simulador mostra uma rodada por vez, com os botões travando nas pontas
- O rodapé mostra o autor com link e a chave Pix com o botão de copiar

## Teste antes/depois
- Antes: `/simulador` mostrava o campeonato mais recente
- Depois: `spec/requests/simulador_spec.rb` (lista pública e logada, carrossel, rodada preservada ou com erro, navegação, 404 sem campeonato); `spec/requests/championships_spec.rb` (botão "Simular"); `spec/requests/brand_spec.rb` (autor e Pix); `spec/system/visitor_simulates_championship_spec.rb` (escolher o campeonato e navegar entre rodadas, roda com Chrome)
