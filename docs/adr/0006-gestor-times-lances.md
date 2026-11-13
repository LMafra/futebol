# ADR 0006 — Times do gestor, inscrição, modalidade, rascunho e lances com minuto

- Status: aceito · Data: 2026-11-13
- Fonte: rodada de ajustes "antes de finalizar a tarefa" (2026-11-12), com as decisões tomadas no grill (tickets 0085–0106)
- Relação: muda a posse dos times (ADR 0001, `core`), a origem dos scouts (ADR 0005) e quem cria bolões (ADR 0004). As regras de pontuação e de valorização do ADR 0005 não mudam. Os ADRs 0001–0005 continuam valendo no resto.

## 1. Problema
- **Times globais.** `Core::Team` não tinha dono nem vínculo com campeonato: os campeonatos de um time eram deduzidos das partidas. Um gestor via times de outros gestores, e um time "travado" (que joga em campeonato alheio) não podia ser editado. A regra pedida é outra: "um gestor tem N campeonatos; um campeonato tem N times e N partidas; os times e jogadores pertencem àquele gestor".
- **Sem contato do time.** Não havia como registrar o capitão ou o responsável.
- **Formato preso ao futebol de campo.** O campeonato não sabia se era society, futsal, feminino, infantil…, e os limites do Esquadrão não tinham ponto de partida.
- **Campeonato publicado de imediato.** Ele aparecia no público assim que era criado, mesmo sem times e sem partidas.
- **Escudo por URL.** O escudo era uma URL digitada (`crest_url`), e o campeonato não tinha logo.
- **Scouts sem tempo.** `Cartola::PlayerScore` guardava só totais por jogador e partida. Não dava para registrar "gol aos 32 do 1º tempo", desfazer o último lance nem transmitir a partida ao vivo.
- **Bolão de qualquer um.** Qualquer usuário criava bolão; o pedido é que só Gestor e Admin criem, e que o usuário apenas participe.

## 2. Decisão
### Times do gestor e inscrição
- `core_teams.manager_id` (nulo = time do Admin). O gestor só vê, edita e escala os próprios times; os jogadores seguem o time.
- **Inscrição** (`core_championship_teams`: `championship_id`, `team_id`, índice único) liga um time a um campeonato do mesmo gestor. Um time pode se inscrever em vários campeonatos do seu gestor.
- `Core::Match` só aceita mandante e visitante inscritos no campeonato. É validado no model, e o seletor de times mostra só os inscritos.
- **Migração:**
  - o `manager_id` do time vem do gestor dos campeonatos em que ele joga;
  - um time que joga em campeonatos de gestores diferentes é **duplicado**, com seus jogadores, para cada gestor, e as partidas desses gestores passam a apontar para a cópia;
  - um time só de campeonatos sem gestor fica do Admin;
  - as inscrições são preenchidas a partir das partidas.
  - A migração tem `down`.
- **Capitão:** contato do time, sem login. `captain_name` e `captain_phone`, com telefone BR validado.

### Modalidade e rascunho
- Quatro campos obrigatórios no campeonato:
  - **Tipo** (`kind`): campo, society, futsal, futvôlei;
  - **Gênero** (`gender`): masculino, feminino, misto;
  - **Categoria** (`category`): infantil, base, adulto, master;
  - **Nível** (`level`): amador, profissional.
- O Tipo **sugere** os limites do Esquadrão (por exemplo, society com 1 goleiro e 6 na linha), mas o gestor pode editar: há futebol de campo com 9 na linha, society com 5, e outras variações.
- `status`: `draft` (rascunho) ou `published`. O rascunho não aparece no público. O assistente de criação salva o rascunho a cada etapa, e só a etapa Revisão publica.

### Imagens
- `has_one_attached :crest` no time e `:logo` no campeonato, via Active Storage: disco em desenvolvimento, R2 em produção (`config/storage.yml`).
- Validação de tipo (PNG, JPEG, WebP, SVG) e tamanho (2 MB), com variantes `thumb` e `medium`.
- `crest_url` sai depois de migrar os escudos existentes (download best-effort).

### Lances (`Cartola::ScoutEvent`)
- Um **lance** é um registro com partida, jogador, time, `stat` (G, A, GC, CA, CV, DP, DE), `period` (1º tempo, 2º tempo, prorrogação, pênaltis), `minute` e `discarded_at`.
- `Cartola::PlayerScore` continua sendo a fonte da pontuação, mas seus contadores passam a ser **derivados** dos lances mantidos. Lançar e desfazer recalculam o `PlayerScore` na mesma transação.
- SG continua calculado; "Jogou" e "Destaque" continuam marcações do `PlayerScore`, sem lance.
- O "−" desfaz o último lance daquele jogador e estatística (`discarded_at`); nada é apagado.
- O backfill cria lances sem minuto para os totais que já existem. Os pontos não mudam.
- Os serviços de lance, finalização e reversão transmitem a partida ao vivo (Turbo Streams; Solid Cable em produção).

### Bolão
- `Bolao::PoolPolicy#create?` passa a ser só de Gestor (no próprio campeonato) e Admin. O usuário entra por código.
- **Migração:** o dono de cada bolão existente passa a ser o gestor do campeonato; sem gestor, o dono continua. O dono antigo continua membro.
- O Gestor pode corrigir palpites e escalações a qualquer momento, com motivo obrigatório e registro no `AuditLog`. Se a partida já foi pontuada, os pontos são recalculados pelos serviços de pontuação e reversão já existentes.

## 3. Alternativas
| | A — time do gestor + inscrição (escolhida) | B — times globais com vínculo por campeonato | C — time copiado por campeonato |
|---|---|---|---|
| posse | do gestor | de ninguém | do campeonato |
| reaproveitar o time em outro campeonato | sim, inscrevendo | sim | não: cópia nova a cada campeonato |
| edição | o dono edita sem afetar outros gestores | edição afeta todos | isolada, mas duplica jogadores e histórico |
| migração | duplicar só os times compartilhados entre gestores | nenhuma | duplicar todos |

| | Lances com minuto (escolhida) | Só totais (anterior) | Horário real (timestamp) |
|---|---|---|---|
| ao vivo | sim | não | sim |
| desfazer o último | sim | só −1 no total | sim |
| esforço no campo | digitar o minuto | nenhum | nenhum, mas o horário de lançamento não é o minuto do jogo |

## 4. Consequências
- `Core::TeamPolicy` deixa de ter "time travado": o escopo do gestor é `manager_id`.
- As telas de time, partida e participantes passam a navegar pela árvore Campeonato › Partidas › Partida e Times › Time › Jogadores (TICKET-0094).
- A página de scouts e a de finalização viram uma tela única da partida (TICKET-0097); as URLs antigas redirecionam.
