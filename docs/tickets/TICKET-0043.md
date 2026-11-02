# TICKET-0043 — Simulador pelos cards, rodadas passadas no carrossel e rolagem guiada na home

- Deps: TICKET-0041, TICKET-0042
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública e Simulador); [ADR 0003](../adr/0003-simulador.md)
- Estado anterior: o Simulador ficava no canto superior direito do cabeçalho; o carrossel do simulador só tinha as rodadas com jogos em aberto; a home rolava livremente

## Escopo
- O cabeçalho deixa de ter o link "Simulador". Cada card de campeonato da home ganha o botão "Simular" (aria-label "Simular <campeonato>"), ao lado de "Ver ranking completo". Continuam valendo o card do módulo Simulador, o atalho do hero para quem está logado e o botão da página do campeonato
- O carrossel do simulador ("Rodadas") passa a ter todas as rodadas do campeonato. Rodadas só com jogos encerrados aparecem como "Rodada N · encerrada", com o placar final de cada jogo e sem campos; rodadas com algum jogo em aberto seguem com os campos. O carrossel abre na primeira rodada com jogo em aberto, então "Anterior" mostra os resultados das rodadas passadas. Sem jogos em aberto, o aviso continua e as rodadas encerradas aparecem, sem o botão "Projetar tabela"
- Home com scroll snap obrigatório no eixo vertical: cada seção encaixa no topo (`*:snap-start`, com `scroll-mt-8`), e o cabeçalho e o rodapé também são pontos de encaixe, para dar para voltar ao topo e chegar ao rodapé. O `scroll-snap-type` precisa ficar no `<html>`, cujos atributos o Turbo mantém entre visitas, então o Stimulus `scroll_snap_controller` liga o snap ao entrar na home e desliga ao sair. Sem JS, a home rola livremente

## Paths
- `app/views/layouts/application.html.erb`, `app/views/home/{index,_championships}.html.erb`
- `app/controllers/simulador/simulations_controller.rb`, `app/helpers/simulador_helper.rb`
- `app/views/simulador/simulations/{show,preview,_simulator}.html.erb`
- `app/javascript/controllers/{rounds,scroll_snap}_controller.js`

## Pronto quando
- O cabeçalho não tem "Simulador" e cada card de campeonato tem "Simular"
- No simulador, "Anterior" a partir da primeira rodada em aberto mostra o resultado da rodada anterior
- A home rola seção a seção; as outras páginas, não

## Teste antes/depois
- Antes: o carrossel começava na primeira rodada em aberto, sem rodadas encerradas; o cabeçalho tinha "Simulador"
- Depois: `spec/requests/home_spec.rb` (botão "Simular" no card, cabeçalho sem Simulador, scroll snap só na home); `spec/requests/simulador_spec.rb` (todas as rodadas, início na primeira em aberto, resultado das encerradas, campeonato todo encerrado, rodada preservada ou com erro); `spec/system/visitor_simulates_championship_spec.rb` (da home ao simulador pelo card, "Anterior" até o resultado, snap desligado fora da home; roda com Chrome)
