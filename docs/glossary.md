# Glossary

- **Craquefy**: marca do produto, vinda de `brand.name` no `config/locales/pt-BR.yml`. O repositório, os engines, as tabelas e as classes continuam com os nomes internos (`futebol`, `cartola`, `Cartola::...`). _Avoid_: Futebol como nome do produto.
- **Esquadrão**: nome visível do módulo de fantasy (engine `cartola`, rotas `/esquadrao`). Use `module_label(:fantasy)`. _Avoid_: Cartola em texto visível.
- **Scout**: estatística oficial de um jogador numa Match (G, A, SG, DP, DE, CA, CV, GC, Jogou, Destaque), lançada pelo admin e gravada em `cartola_player_scores`. _Avoid_: estatística, evento.
- **Match**: partida entre dois times numa data (`match_date`). _Avoid_: jogo, fixture, kickoff.
- **Scoring**: cálculo dos pontos de todos os palpites/escalações de uma Match encerrada.
- **Reversal**: desfazer um Scoring já aplicado, mantendo trilha de auditoria.
- **Prediction**: palpite de placar de um usuário num Pool do Bolão.
- **Pool**: grupo de usuários que disputam um Bolão.
- **Lineup**: escalação de um Squad numa rodada do Cartola.
- **Preview**: cálculo sem persistir (dry-run) dos pontos que um placar candidato geraria.
- **Gestor de campeonato**: usuário com `role: :manager` e `manager_status: :approved`; opera em `/gestor` só campeonatos cujo `manager_id` é ele (cadastro, partidas, scouts, finalização e reversão). Pedido via `/gestor/solicitar`; aprovação no admin. _Avoid_: chamar gestor de "admin"; o admin vê a plataforma inteira.
