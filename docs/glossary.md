# Glossary

- **Craquefy**: marca do produto, vinda de `brand.name` no `config/locales/pt-BR.yml`. O repositório, os engines, as tabelas e as classes continuam com os nomes internos (`futebol`, `cartola`, `Cartola::...`). _Avoid_: Futebol como nome do produto.
- **Esquadrão**: nome visível do módulo de fantasy (engine `cartola`, rotas `/esquadrao`). Use `module_label(:fantasy)`. _Avoid_: Cartola em texto visível.
- **Scout**: estatística oficial de um jogador numa Match (G, A, SG, DP, DE, CA, CV, GC, Jogou, Destaque), gravada em `cartola_player_scores`. Os contadores (G, A, DP, DE, CA, CV, GC) são a soma dos Lances mantidos; SG é calculado; Jogou e Destaque são marcados direto. _Avoid_: estatística.
- **Lance**: um acontecimento de scout com minuto e tempo (`Cartola::ScoutEvent`: G, A, GC, CA, CV, DP ou DE; 1º tempo, 2º tempo, prorrogação, pênaltis). Desfazer marca `discarded_at`, nunca apaga. _Avoid_: evento, jogada.
- **Match**: partida entre dois times numa data (`match_date`). _Avoid_: jogo, fixture, kickoff.
- **Scoring**: cálculo dos pontos de todos os palpites/escalações de uma Match encerrada.
- **Reversal**: desfazer um Scoring já aplicado, mantendo trilha de auditoria.
- **Prediction**: palpite de placar de um usuário num Pool do Bolão.
- **Pool**: grupo de usuários que disputam um Bolão. Criado só por Gestor (no próprio campeonato) ou Admin; o usuário entra por código.
- **Lineup**: escalação de um Squad numa rodada do Cartola.
- **Preview**: cálculo sem persistir (dry-run) dos pontos que um placar candidato geraria.
- **Gestor de campeonato**: usuário com `role: :manager` e `manager_status: :approved`; opera em `/gestor` só campeonatos cujo `manager_id` é ele (cadastro, partidas, scouts, finalização e reversão). Pedido via `/gestor/solicitar`; aprovação no admin. _Avoid_: chamar gestor de "admin"; o admin vê a plataforma inteira.
- **Time do gestor**: `Core::Team` com `manager_id`; só o dono o vê e edita. Sem `manager_id`, é do Admin. _Avoid_: time global.
- **Inscrição**: vínculo de um time com um campeonato do mesmo gestor (`core_championship_teams`). Só times inscritos entram nas partidas do campeonato. _Avoid_: participação, cadastro no campeonato.
- **Capitão**: contato responsável pelo time (nome e telefone), sem login. Não confundir com o capitão da escalação do Esquadrão, que dobra os pontos. _Avoid_: dono, responsável.
- **Modalidade**: Tipo (campo, society, futsal, futvôlei), Gênero (masculino, feminino, misto), Categoria (infantil, base, adulto, master) e Nível (amador, profissional) do campeonato. O Tipo sugere os limites do Esquadrão, que continuam editáveis. _Avoid_: formato, categoria como sinônimo do conjunto.
- **Rascunho**: campeonato com `status: draft`, salvo pelo assistente de criação e invisível no público até a Revisão publicar. _Avoid_: pendente, inativo.
