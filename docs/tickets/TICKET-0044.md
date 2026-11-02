# TICKET-0044 — Tabela projetada no lugar da atual e "Zerar simulação"

- Deps: TICKET-0043
- Skill: [W]tdd
- MCP: —
- Spec: §10 (Simulador); [ADR 0003](../adr/0003-simulador.md)
- Estado anterior: a tabela atual ficava fixa à esquerda e a projetada aparecia acima das rodadas, na outra coluna; não havia como voltar ao estado inicial sem recarregar a página

## Escopo
- O Turbo Frame `simulador` passa a envolver a tabela e as rodadas. Ao projetar, "Tabela projetada" (com a variação de posição) substitui "Tabela atual" no mesmo lugar; com placar inválido, a tabela atual continua e os erros aparecem nas rodadas
- Depois de projetar (válido ou não), o cabeçalho da tabela mostra "Zerar simulação": um link para o próprio simulador, carregado no frame, que volta à tabela atual, limpa os placares (jogos ao vivo voltam com o placar real) e reabre na primeira rodada em aberto. Na primeira visita o botão não aparece
- O aviso de limite de projeções (429) continua substituindo o frame inteiro

## Paths
- `app/views/simulador/simulations/{show,preview,_simulator}.html.erb`

## Pronto quando
- Projetar troca a tabela atual pela projetada, sem uma segunda tabela na tela
- "Zerar simulação" volta à tabela atual com os campos vazios

## Teste antes/depois
- Antes: `spec/requests/simulador_spec.rb` procurava a tabela atual fora do frame e a projetada dentro dele
- Depois: `spec/requests/simulador_spec.rb` (tabela atual sem botão; projetada no lugar da atual com "Zerar simulação"; inválido mantém a atual e mostra o botão); `spec/system/visitor_simulates_championship_spec.rb` (projetar e zerar; roda com Chrome)
