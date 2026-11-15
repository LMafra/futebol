# TICKET-0113 — Seeds com cenários de teste de todas as funcionalidades

- Deps: TICKET-0112
- Skill: [W]tdd
- MCP: playwright
- Origem: pedido do usuário (2026-11-14): "limpe a base local e crie um seed para testar todas as funcionalidades do sistema"

## Descrição
Os seeds cobriam o Brasileirão (rodadas pontuadas, ao vivo e agendadas), os campeonatos pequenos, o Bolão, o Esquadrão e o gestor demo. Faltavam dados para boa parte do que foi construído depois:
- partidas "Encerrada", "Revertida" e agendada com horário passado;
- lances com minuto e lance desfeito;
- edição depois de pontuada e Histórico da partida;
- dedução de pontos;
- correções no Bolão e no Esquadrão;
- pedidos de gestor;
- usuário anonimizado;
- rascunho de campeonato;
- importação CSV;
- escudos e auditoria.

A base local também acumulava restos de testes manuais ("Copa Wizard …", "Rascunho …").

## Ambiente
- Desktop 1440px, Chromium 1208 (Playwright), base local recriada com `bin/rails db:reset`
- Gestor (`gestor@demo.local`), Admin (`admin@futebol.dev`) e visitante

## Severidade
Média: sem esses dados, testar à mão exigia montar cada situação pela interface antes de cada verificação.

## Passos para reproduzir
1. `bin/rails db:reset`.
2. Entrar como gestor e procurar uma partida revertida, uma encerrada sem pontuação ou uma com histórico.
3. Entrar como admin e procurar um pedido de gestor, uma importação CSV ou registros de auditoria.

## Esperado
Depois do `db:reset`, cada funcionalidade tem pelo menos um caso pronto para testar, criado pelos mesmos serviços das telas. A segunda carga não cria nada.

## Atual
Nenhuma partida "Encerrada" ou "Revertida", nenhum registro de auditoria, nenhuma dedução, importação, pedido de gestor ou usuário anonimizado.

## Correção
- **`db/seeds/scenarios.rb`:** a "Copa dos Testes" do gestor demo.
  - Campeonato society com premiação e logo.
  - 4 times com escudo, capitão e elenco.
  - Bolão `TESTES` com regra própria (12/6) e palpites de `demo1`–`demo5` e de Olga (anonimizada depois).
  - O organizador corrige o palpite de `demo2` numa partida já pontuada e remove `demo5`.
  - Dedução ativa (Esporte Clube Ensaio, −3, W.O.) e outra revogada.
- **`db/seeds/scenario_matches.rb`:** uma partida por situação, com lances gravados por `Scouts::RecordEvent`.
  - Pontuada 2 × 1 e editada depois para 2 × 2, com Destaque (dois `rescore`).
  - Pontuada e revertida com motivo.
  - Encerrada sem pontuação, como a fila antiga deixava.
  - Ao vivo com um lance desfeito.
  - Agendada com o horário já passado.
  - Agendada e remarcada com motivo.
- **`db/seeds/scenario_platform.rb`:** os casos de plataforma.
  - Capitão de `demo1` corrigido na Copa da Várzea Paulista.
  - Pedido de gestor pendente (`pedido@demo.local`) e recusado com motivo (`recusado@demo.local`).
  - Participante anonimizada.
  - Rascunho "Copa Feminina de Futsal".
  - Duas importações CSV pelo `ProcessCsvImportJob`: uma concluída (rodada 4 da Copa dos Testes, 2 linhas) e uma com falha (time desconhecido).
- **Idempotência e uploads:**
  - os cenários rodam uma vez, e uma base que já tem a Copa dos Testes fica como está;
  - as datas são relativas à primeira carga;
  - escudos, logo e CSV sobem com `ActiveStorage::Blob.create_and_upload!`. O `attach(io:)` só envia depois do commit da transação dos seeds, tarde demais para o job do CSV.
- **`db/seeds.rb`:** carrega os três arquivos. A linha `seeds ok` passou a contar lances, deduções, importações e registros de auditoria.
- **`spec/seeds_spec.rb`:**
  - "campeonatos pequenos" são os do YAML;
  - os testes de ranking e palpites do demo ignoram a Copa dos Testes;
  - a limpeza inclui os novos modelos e o ActiveStorage;
  - dois testes novos cobrem os cenários.
- **Documentação:** tabela "Cenários de teste" em `docs/OPERATIONS.md` (o que testar, onde, com qual login) e menção no README.

## Evidência
- `bin/rails db:reset`: `seeds ok (… Core::Match=557, Core::User=10, Cartola::ScoutEvent=14, Core::PointDeduction=2, Core::CsvImport=2, Core::AuditLog=32)`; um `db:seed` em seguida dá as mesmas contagens.
- `spec/seeds_spec.rb`: 28 exemplos, 0 falhas, com a carga dupla sem diferença nas contagens.
- Navegador (`tmp/pw/scenarios0113.js`): 19 páginas com 200.
  - As seis partidas do gestor aparecem como "Pontuada" (11 entradas no histórico), "Revertida", "Encerrada", "Ao vivo", "Agendada" e "Agendada" (remarcada).
  - Também abriram o painel do gestor, o campeonato, a Classificação, o bolão e o rascunho.
  - No admin: painel, partida encerrada, Importações CSV, Usuários, Histórico de auditoria e Classificação; no público: home e campeonato.
- Screenshots: `docs/checkpoints/ux-audit/after-0113/`.

## Pronto quando
- [x] Base local recriada do zero, sem os restos de testes manuais
- [x] Uma partida em cada situação, com lances, edição depois de pontuada e histórico
- [x] Bolão, Classificação, Esquadrão, pedidos de gestor, anonimização, rascunho e importação CSV com dados prontos
- [x] Seeds idempotentes e cobertos pelo `seeds_spec`
- [x] Tabela "Cenários de teste" no `docs/OPERATIONS.md`
