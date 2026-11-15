# Auditoria do fluxo do usuário padrão (role: user)

Escopo: papel **Usuário** (conta autenticada que não é `admin?` nem `manager?`).
Data: 2026-11-15. Fonte: código atual em `main` / branch `feature/ux-usuario-padrao`.
Decisões de produto (grilling): entrada em bolão **só por código**; sem join público; UI usa **Classificação** (não Ranking).

## Mapa Cadastro → login → home → bolão → Esquadrão → Simulador

| Etapa | Rota | Auth | O que acontece hoje |
|---|---|---|---|
| Cadastro | `GET/POST /signup` | público | Cria conta, inicia sessão, redireciona para `root_path` (`UsersController#create`) |
| Login | `GET /entrar` → `POST /session` | público | `SessionsController#create` → `after_authentication_url` → `root_url` para role comum |
| Home | `GET /` | público | `HomeController#index` — mesmos campeonatos públicos para visitante e logado |
| Conta | `GET /minha-conta` | logado | Nome, e-mail, consentimento de perfil público |
| Bolão (lista) | `GET /pools` | logado | Só pools com membership; form de entrar por **código** |
| Bolão (entrar) | `POST /pools/join` | logado | `find_by(code:)`; cria membership |
| Bolão (show) | `GET /pools/:id` | membro | Detalhe do pool |
| Palpites | `GET/POST /pools/:id/bets` | membro | Placar até `match_date` (countdown Stimulus) |
| Esquadrão | `GET /esquadrao` | logado | Escalação da rodada; budget bar existe; sem tour |
| Classificação Esquadrão | `GET /esquadrao/rankings` | logado | Classificação do fantasy |
| Simulador | `GET /simulador`, `/simulador/:id` | público | “E se”; logado vê `published`, visitante só `publicly_visible` |
| Pedido gestor | `GET /gestor/solicitar` | logado | Fora do fluxo diário de jogo |

```text
Visitante → / ou /simulador
         → /entrar ou /signup
              ↓
         root_url (home pública)  ← fricção: igual ao visitante
              ↓
    Menu "Minha conta" → /pools (código) | /esquadrao | /minha-conta
```

## Pode vs não pode (role: user)

### Pode

- Cadastrar-se e autenticar-se (`/signup`, `/entrar`).
- Ver home e páginas públicas de campeonato; usar o Simulador.
- Entrar em bolão **com código** (`join?` se autenticado).
- Ver e palpitar em bolões dos quais é membro.
- Montar/editar a própria escalação do Esquadrão; ver classificação.
- Editar `/minha-conta`; solicitar ser gestor.

### Não pode

- Criar bolão (`Bolao::PoolPolicy#create?` — só admin ou gestor do campeonato).
- Ver pool sem membership (`show?` exige `member?`; scope = memberships).
- Entrar em bolão sem código (não há join por `pool_id` / lista pública de pools).
- Operar `/admin` ou `/gestor` (exceto solicitar).
- Ver/editar escalação de outro usuário (`LineupPolicy` — só dono do squad).

## Cinco fricções (com evidência)

| # | Fricção | Evidência | Correção (bloco) |
|---|---|---|---|
| 1 | Usuário logado cai na **home pública** idêntica ao visitante; não há área pessoal. | `Authentication#area_root_url` → `else root_url`; `UsersController#create` → `root_path`; não existe `/minha-area`. `HomeController#index` não ramifica por `Current.user`. | Criar `/minha-area` com KPIs e pendências; redirect pós-login/signup → `/minha-area` (**B**). Banner na home logada (**F**). |
| 2 | Entrada em bolão depende só do **código**; lista `/pools` não tem busca por nome entre os bolões do usuário; empty state fraco. | `PoolsController#join` usa `params[:code]`; index lista `policy_scope` sem `params[:q]`. | Busca por nome nos **meus** bolões; cards com posição; empty state pedindo código ao organizador (**C**, **G**). *Sem* join público (fora de escopo). |
| 3 | Esquadrão **sem onboarding**; formação, orçamento e capitão não são explicados na primeira visita. | Sem tour em `Cartola::LineupsController` / views; `BudgetBarComponent` existe mas não há banner de primeiros passos. | Tour banner 3 passos + dismiss em `session`; badges de posição; feedback inline (**D**). |
| 4 | **Prazos** incompletos na jornada: palpites têm countdown na lista de partidas, mas não há área de lembretes; escalação **não** mostra nem aplica fechamento. | Countdown em `Bolao::MatchListComponent` + `countdown_controller.js`; sem alerta agregado; lineup sem deadline no controller. | Query `Users::ClosingSoonMatches` em `app/`; alertas em `/minha-area`; badge + bloqueio T−15 min na escalação (**E**, pendências em **B**). |
| 5 | Simulador é público, mas **não há link contextual** na área do usuário logado (menu/conta não aponta; home não destaca “simular este campeonato” para quem participa). | Menu em `application.html.erb`: conta, bolões, esquadrão, rankings — sem Simulador. Home não personaliza CTAs por participação. | Card Simulador em `/minha-area` (**B**); badge “Você participa” + “Simular este campeonato” na home (**F**). |

## Mapa fricção → blocos B–F

| Bloco | Entrega |
|---|---|
| **B** | `/minha-area`, KPIs, pendências, redirect pós-auth, link “Minha área” |
| **C** | Busca por nome (meus bolões), cards, empty state, código copiável (owner) |
| **D** | Tour Esquadrão, budget visível, badges de posição, feedback inline |
| **E** | Badges/alertas de prazo; T−15 na escalação (badge + bloqueio) |
| **F** | Home logada (banner + “Você participa” + simulador contextual); menu |

## Critérios deste bloco

- [x] `docs/ux/user-flow-audit.md` com rotas, fricções e correções
- [x] 5 fricções com evidência
- [x] Nenhum código de `app/` alterado neste bloco
