<a id="readme-top"></a>

[![CI][ci-shield]][ci-url]
[![Ruby][ruby-shield]][ruby-url]
[![Rails][rails-shield]][rails-url]
[![License: MIT][license-shield]][license-url]

<br />
<div align="center">
  <a href="https://github.com/LMafra/futebol">
    <img src="docs/assets/logo.svg" alt="Logo" width="96" height="96">
  </a>

  <h3 align="center">Craquefy</h3>

  <p align="center">
    O campeonato do seu jeito: Bolão, Esquadrão e Simulador em um monólito modular Rails 8.
    <br />
    <sub>Repo GitHub: futebol; marca: Craquefy.</sub>
    <br />
    <a href="docs/README.md"><strong>Explore a documentação »</strong></a>
    <br />
    <br />
    <a href="https://futebol-web.onrender.com">App</a>
    &middot;
    <a href="docs/spec-v3.md">Spec</a>
    &middot;
    <a href="docs/tickets/INDEX.md">Tickets</a>
    &middot;
    <a href="docs/adr/0001-arch.md">ADR 0001</a>
    &middot;
    <a href="docs/adr/0002-activeadmin-rails81.md">ADR 0002</a>
    &middot;
    <a href="docs/checkpoints/STATUS.md">Status</a>
  </p>
</div>

<details>
  <summary>Sumário</summary>
  <ol>
    <li><a href="#sobre-o-projeto">Sobre o projeto</a>
      <ul><li><a href="#construído-com">Construído com</a></li></ul>
    </li>
    <li><a href="#começando">Começando</a></li>
    <li><a href="#infraestrutura-de-produção">Infraestrutura de produção</a></li>
    <li><a href="#uso">Uso</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contribuindo">Contribuindo</a></li>
    <li><a href="#licença">Licença</a></li>
    <li><a href="#contato">Contato</a></li>
    <li><a href="#agradecimentos">Agradecimentos</a></li>
  </ol>
</details>

## Sobre o projeto

Plataforma Rails 8 com engines `core`, `bolao`, `cartola` e `simulador` para quem acompanha o campeonato com os amigos: no **Bolão**, cada participante palpita o placar das partidas de um grupo; no **Esquadrão** (engine `cartola`), monta a escalação da rodada com capitão, respeitando os limites por posição do campeonato, e compra os jogadores com a carteira de moedas; o **Simulador** projeta a classificação ("e se") a partir de placares hipotéticos, aberto a visitantes ([ADR 0003](docs/adr/0003-simulador.md)). Partidas, times e usuários vivem no `core`; o admin cadastra, importa e finaliza partidas, e a pontuação é calculada por jobs.

Decisões de arquitetura:

- Monolito modular Rails 8.1 + Postgres; engines dependem só de `core` ([ADR 0001](docs/adr/0001-arch.md))
- Pontuação idempotente (`scoring_token`) e reversível (`revert_match!` reverte antes de zerar `scores_calculated_at`) ([ADR 0001](docs/adr/0001-arch.md))
- Design "Placar de Domingo": verde-campo, laranja-cartola, Fraunces + Source Sans 3 ([direção](docs/design/0001-direction.md), [crítica](docs/design/0001-critique.md))
- Admin em ActiveAdmin `4.0.0.beta23`, pinado no Gemfile ([ADR 0002](docs/adr/0002-activeadmin-rails81.md)); é um pré-release, e a política de atualização está em [OPERATIONS.md](docs/OPERATIONS.md#activeadmin)

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

### Construído com

[![Ruby][ruby-badge]][ruby-url]
[![Rails][rails-badge]][rails-url]
[![PostgreSQL (Supabase)][supabase-badge]][supabase-url]
[![Solid Queue][solid-queue-badge]][solid-queue-url]
[![ActiveAdmin][activeadmin-badge]][activeadmin-url]
[![ViewComponent][view-component-badge]][view-component-url]
[![Tailwind CSS][tailwind-badge]][tailwind-url]
[![OpenObserve][openobserve-badge]][openobserve-url]
[![Render][render-badge]][render-url]

Infra: Render + Supabase (Postgres) + R2 + Resend + OpenObserve self-hosted ([infraestrutura](#infraestrutura-de-produção), [MCPs](docs/mcp/README.md)). Em produção: [futebol-web.onrender.com](https://futebol-web.onrender.com) no Render (plano free, Ohio) com Postgres no Supabase (`sa-east-1`).

## Começando

### Pré-requisitos

- Ruby 3.3.6 (`.ruby-version`) e Bundler (`gem install bundler`)
- Docker, para o Postgres 18 local

### Instalação

```bash
git clone https://github.com/LMafra/futebol.git && cd futebol
docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev   # http://localhost:3000
```

`bin/setup` faz tudo isso de uma vez. Hooks, variáveis, OpenObserve local e deploy: [docs/OPERATIONS.md](docs/OPERATIONS.md).

### Deploy

O web service `futebol-web` roda o [`Dockerfile`](Dockerfile) no Render; o `bin/docker-entrypoint` aplica as migrations (`db:prepare`) no boot pelo session pooler do Supabase (porta 5432), e o app usa o transaction pooler (porta 6543). Sem worker no plano free: o Solid Queue roda dentro do Puma (`SOLID_QUEUE_IN_PUMA=1`). O auto-deploy está ligado, com gatilho `commit`: cada commit na `main` vira deploy. Para refazer um deploy sem commit novo, use o Dashboard (Manual Deploy) ou o MCP do Render (`trigger_deploy`).

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://futebol-web.onrender.com/up   # 200
```

No free tier, o Render hiberna o web após 15 min sem tráfego, e o Supabase pausa o projeto após 7 dias sem atividade. Variáveis, poolers, retomada do projeto e passos ainda manuais: [OPERATIONS.md → Deploy](docs/OPERATIONS.md#deploy-render--supabase).

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

## Infraestrutura de produção

As variáveis ficam documentadas em [`.env.example`](.env.example) e, em produção, nas env vars do `futebol-web` no Render (ou no grupo `futebol`, se o Blueprint do [`render.yaml`](render.yaml) estiver em uso). Nenhum valor real entra no repositório.

| Peça | Onde está | Passo manual pendente |
|---|---|---|
| [OpenObserve self-hosted](#openobserve-self-hosted) | `docker/openobserve/docker-compose.yml` + `OTEL_EXPORTER_OTLP_*` | escolher o host (VPS) e definir `OTEL_EXPORTER_OTLP_*` no Render |
| [Cloudflare R2](#cloudflare-r2) | serviço `r2` em `config/storage.yml` | buckets criados; falta gerar o token S3 e definir `R2_*` |
| [Resend](#resend) | SMTP em `config/environments/production.rb` | conta e API key prontas (SMTP validado); falta verificar o domínio e definir `RESEND_*` no Render |
| [Keep-alive](#keep-alive) | `.github/workflows/keep-alive.yml` | nenhum: o secret `RENDER_APP_HOST` já está no GitHub; começa a valer com o merge na `main` |

### OpenObserve self-hosted

Traces e logs saem por OTLP/HTTP para um OpenObserve self-hosted ([`config/initializers/opentelemetry.rb`](config/initializers/opentelemetry.rb)). Para subir localmente (UI em [localhost:5080](http://localhost:5080), login `root@example.com` / `Complexpass#123`, ou `ZO_ROOT_USER_*`):

```bash
docker compose -f docker/openobserve/docker-compose.yml up -d
```

| Variável | Valor |
|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | URL base da organização: `http://localhost:5080/api/default`. O app acrescenta `/v1/traces` e `/v1/logs`. Vazia: development usa esse padrão e production não exporta. |
| `OTEL_EXPORTER_OTLP_HEADERS` | `authorization=Basic <base64>,organization=default`, com o base64 gerado por `echo -n 'email:password' \| base64` |
| `ZO_ROOT_USER_EMAIL`, `ZO_ROOT_USER_PASSWORD` | usuário root do container |

Para usar uma instância remota (um VPS com o mesmo `docker-compose.yml` e a porta 5080 exposta), basta trocar o endpoint, por exemplo `https://<host>:5080/api/default`, e as credenciais no header. O Render free não roda Docker Compose, então o OpenObserve de produção fica num host separado. A edição open-source é gratuita; a Enterprise é gratuita até 50 GB/dia de ingestão. Detalhes: [OPERATIONS.md → Observabilidade](docs/OPERATIONS.md#observabilidade-opentelemetry--openobserve).

### Cloudflare R2

Buckets R2: `futebol-dev` e `futebol-prod`. O Active Storage usa o serviço `r2` de [`config/storage.yml`](config/storage.yml) (S3-compatível, `region: auto`): production grava em `futebol-prod`, e development usa disco, ou `futebol-dev` com `ACTIVE_STORAGE_SERVICE=r2`.

| Variável | Valor |
|---|---|
| `R2_ACCOUNT_ID` | Account ID da Cloudflare; monta o endpoint `https://<account_id>.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | token S3 do R2 (R2 → Manage API tokens) |
| `R2_ENDPOINT` | opcional, sobrescreve o endpoint montado |
| `R2_BUCKET_DEV`, `R2_BUCKET_PROD` | `futebol-dev` e `futebol-prod` |

Os dois buckets já existem (região ENAM). Passo manual: gerar o token S3 (R2 → Manage API tokens) e definir `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID` e `R2_SECRET_ACCESS_KEY` ([OPERATIONS.md → Storage](docs/OPERATIONS.md#storage-cloudflare-r2)).

### Resend

Production envia e-mail pelo SMTP do Resend ([`config/environments/production.rb`](config/environments/production.rb)): `smtp.resend.com`, porta 465 com TLS, usuário `resend` e a API key como senha.

1. Crie a conta em [resend.com](https://resend.com) e gere uma API key (`re_xxxxxxxxx`) com permissão Sending access.
2. Em Domains, cadastre e verifique o domínio do remetente (registros SPF/DKIM no DNS). Sem isso, `onboarding@resend.dev` só entrega para o e-mail do dono da conta.
3. No Render (env vars do `futebol-web`), defina `RESEND_API_KEY` e `RESEND_FROM` (ex.: `Craquefy <bolao@seu-dominio.com>`).

Teste de envio e detalhes: [OPERATIONS.md → E-mail](docs/OPERATIONS.md#e-mail-resend).

### Keep-alive

O web free do Render dorme após 15 min sem tráfego. O workflow [`keep-alive.yml`](.github/workflows/keep-alive.yml) pinga `https://$RENDER_APP_HOST/up` a cada 14 min (`*/14 * * * *`) e também roda à mão (`workflow_dispatch`).

- Secret do GitHub `RENDER_APP_HOST` = `futebol-web.onrender.com` (só o host): Settings → Secrets and variables → Actions, ou `gh secret set RENDER_APP_HOST --body futebol-web.onrender.com`.
- O agendamento só roda a partir da `main`, pode atrasar e é desativado pelo GitHub depois de 60 dias sem atividade no repositório.
- Alternativa: um job no [cron-job.org](https://cron-job.org) com GET em `https://futebol-web.onrender.com/up` a cada 14 min.

Detalhes e custo em horas free: [OPERATIONS.md → Keep-alive](docs/OPERATIONS.md#keep-alive).

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

## Uso

1. **Campeonato:** em [`/admin`](http://localhost:3000/admin), cadastre o campeonato e os times (Cadastros) e importe as partidas por CSV (Cadastros → Importações CSV). O `match_date` do CSV é lido no horário de Brasília, o fuso do app (`config.time_zone = 'Brasilia'`); o banco guarda em UTC.
2. **Bolão:** crie um bolão em [`/pools/new`](http://localhost:3000/pools/new) e compartilhe o código; os amigos entram por [`/pools`](http://localhost:3000/pools).
3. **Palpites:** cada participante palpita o placar das partidas na página de palpites do bolão.
4. **Escalação:** monte o time da rodada no Esquadrão em [`/esquadrao`](http://localhost:3000/esquadrao), com um capitão, e acompanhe os rankings em [`/esquadrao/rankings`](http://localhost:3000/esquadrao/rankings).
5. **Scouts e finalização:** no `/admin` ou, para o próprio campeonato, no `/gestor`, Pontuação → Scouts da partida lança os scouts; Finalizar confirma o placar derivado e o job pontua palpites e escalações (Reverter desfaz).

Login demo (só development/test, criado pelo `db:seed`): `demo1@demo.local` … `demo5@demo.local` / `demo-futebol`, o gestor `gestor@demo.local` / `demo-futebol` (campeonato demo atribuído) e o admin `admin@futebol.dev` / `futebol-admin`, com o bolão `DEMO01` já pontuado e mais 5 campeonatos pequenos (6 a 12 times; 3 públicos e 2 privados) com jogos hoje, para a seção "Jogos de hoje" da home. Detalhes dos dados demo, filas e comandos: [docs/OPERATIONS.md](docs/OPERATIONS.md).

Em produção não há contas demo, porque a senha acima é pública: o seed cria só o admin, com senha forte guardada fora do repositório, além de times, jogadores e partidas. Novas contas saem do cadastro público em [`/signup`](http://localhost:3000/signup) (link "Criar conta" no login); ainda não há tela de usuários no admin.

### Home pública

[`/`](http://localhost:3000/) abre sem login: hero com "Entrar" e "Criar conta", contadores, os três módulos, jogos de hoje, os campeonatos públicos com o Top 3 do Bolão e do Esquadrão e o top 10 de atletas (jogos, gols, assistências e pontos). Campeonatos marcados como privados no admin ("Campeonato privado?") não aparecem nas listas, mas entram nos contadores (campeonatos, partidas e jogadores no total). Fora do admin, nenhum texto diz se um campeonato é público ou privado. A home encaixa as seções ao parar de rolar perto do início de uma delas (scroll snap por proximidade).

### Níveis de acesso

Três papéis, com áreas separadas no ActiveAdmin e login dedicado onde a conta não serve para a outra área:

| Papel | Onde entra | Escopo |
|---|---|---|
| **Admin** | [`/admin`](http://localhost:3000/admin) ou [`/admin/login`](http://localhost:3000/admin/login) | Plataforma inteira: usuários, importações CSV, auditoria, comentários nos recursos, preview do Bolão |
| **Gestor** | [`/gestor`](http://localhost:3000/gestor) ou [`/gestor/login`](http://localhost:3000/gestor/login) | Só os campeonatos com `manager_id` dele: cadastro, partidas, regras do Bolão, premiação; **scouts**, **finalizar** e **reverter** partidas nesses campeonatos (mesmas telas de Pontuação, em `/gestor`) |
| **Usuário** | [`/entrar`](http://localhost:3000/entrar) | Bolão, Esquadrão, conta e pedido de acesso de gestor em [`/gestor/solicitar`](http://localhost:3000/gestor/solicitar) |

Detalhes dos tickets: [0056–0062](docs/tickets/INDEX.md).

### Admin e Gestor (UI Placar de Domingo)

`/admin` e `/gestor` compartilham o tema **Placar de Domingo** via Tailwind CSS v4 do ActiveAdmin 4: header `pitch` com Fraunces, navegação `paper`/`rule` com item ativo `cartola`, tabelas com thead pitch e zebra paper, formulários com `border-rule` e submit `bg-cartola text-ink`, dashboards em grade 8/4 (admin) e 3/9 (gestor), badges de status e medalhas SVG no ranking. Tokens em `app/assets/stylesheets/active_admin.css`; tickets [0063–0067](docs/tickets/INDEX.md).

### Login

O link "Entrar" leva a [`/entrar`](http://localhost:3000/entrar); páginas que exigem sessão continuam redirecionando para `/session/new`. Operação restringida usa [`/admin/login`](http://localhost:3000/admin/login) e [`/gestor/login`](http://localhost:3000/gestor/login) (campo oculto `area`, para não abrir sessão na área errada). Logado, o cabeçalho mostra o menu "Minha conta" (Minha conta, Meus bolões, Meu esquadrão, Rankings) e "Sair". O rodapé mostra "Área do gestor" para admin ou gestor e "Acesso administrativo" só para admin (visitante ainda vê o link do admin).

### Módulos

| Módulo | Onde | Login |
|---|---|---|
| Bolão | [`/pools`](http://localhost:3000/pools) | sim |
| Esquadrão | [`/esquadrao`](http://localhost:3000/esquadrao) e [`/esquadrao/rankings`](http://localhost:3000/esquadrao/rankings) | sim |
| Simulador | [`/simulador`](http://localhost:3000/simulador) (escolha o campeonato) e `/simulador/:id` | não |

Esquadrão é o nome visível do engine `cartola`; as URLs antigas (`/cartola`, `/cartola/rankings` e as do admin) respondem 301. A marca é Craquefy; o repositório, os engines e as tabelas mantêm os nomes internos ([glossário](docs/glossary.md)).

### Campeonatos públicos

[`/campeonatos/:id`](http://localhost:3000/campeonatos/1) mostra, sem login, as abas Times (classificação), Partidas (uma rodada por vez, `?rodada=`), Bolão e Esquadrão (rankings completos). No Bolão vale a maior pontuação de cada partida entre os bolões do usuário; no Esquadrão, o capitão pontua em dobro. O botão "Simular" (também em cada card de campeonato da home) abre o Simulador desse campeonato, uma rodada por vez: abre na primeira rodada com jogo em aberto, e "Anterior" mostra os resultados das rodadas passadas. Ao projetar, a tabela projetada toma o lugar da atual, e "Zerar simulação" volta ao início. Campeonato privado responde 404.

### Privacidade (consentimento)

Os rankings públicos mostram "primeiro nome + inicial" (ex.: "Lucas M.") só de quem autorizou, no cadastro ou em [`/minha-conta`](http://localhost:3000/minha-conta); os demais aparecem como "Participante", e o e-mail nunca é exibido. Conceder e revogar geram AuditLog com IP, e a anonimização (LGPD) apaga o consentimento.

### Scouts

O admin e o **gestor do campeonato** lançam os scouts oficiais (G, A, DP, DE só para goleiros, CA, CV, GC, Jogou e Destaque) em Pontuação → Scouts da partida, no `/admin` ou `/gestor`; SG é calculado. O placar vem dos gols lançados, e a pontuação do Esquadrão e a valorização dos jogadores seguem o [ADR 0005](docs/adr/0005-esquadrao-pontuacao-valorizacao.md).

## Roadmap

Escopo e contratos em [spec v3](docs/spec-v3.md); trabalho em 62 tickets ([INDEX](docs/tickets/INDEX.md)).

- [x] Monolito modular com 4 engines e Packwerk
- [x] Core, AASM das partidas e pontuação idempotente e reversível com auditoria
- [x] ActiveAdmin + Pundit, autenticação nativa, rate limiting e anonimização (LGPD)
- [x] Import de CSV em streaming e previews de pontuação (Bolão e Cartola)
- [x] Design system com ViewComponents em 4 estados
- [x] Bolão (criar, entrar, palpitar), Cartola (escalação) e seeds de demonstração
- [x] Escopo do Simulador ([ADR 0003](docs/adr/0003-simulador.md))
- [x] CI (lint, testes, system specs, seeds 2×, gitleaks) e `render.yaml`
- [x] Observabilidade com OpenTelemetry → OpenObserve e banco no Supabase
- [x] Primeiro deploy: projeto Supabase e web service `futebol-web` no Render, via MCPs
- [x] 0028: cadastro público em `/signup`
- [x] 0029: Bolão com 2 faixas configuráveis por campeonato ([ADR 0004](docs/adr/0004-bolao-scoring.md))
- [x] 0030: Cartola configurável por campeonato (limites por posição, carteira, valorização, rankings; inclui `core_matches.round`)
- [x] Infra de produção: OpenObserve self-hosted (Docker + OTLP), R2 (`storage.yml`), Resend (SMTP) e keep-alive (GitHub Actions)
- [ ] Pendências manuais de produção: token S3 do R2, domínio do Resend e `R2_*`/`RESEND_*` no Render, host do OpenObserve e `RENDER_DEPLOY_HOOK_URL`
- [x] 0031: Simulador v1 "e se" em [`/simulador`](http://localhost:3000/simulador) (ADR 0003, que o numerava 0029; `core_matches.round` entrou no 0030)
- [x] 0032–0040: home pública, login em `/entrar`, Esquadrão, rankings públicos por campeonato, pt-BR, consentimento, scouts, capitão e valorização ([ADR 0005](docs/adr/0005-esquadrao-pontuacao-valorizacao.md)) e a marca Craquefy
- [x] 0041: Simulador por campeonato (lista em `/simulador`, botão "Simular" na página do campeonato, rodadas em carrossel) e rodapé com autor e "Pague o Café" (Pix)
- [x] 0043: Simulador pelos cards da home (fora do cabeçalho), rodadas passadas no carrossel e rolagem guiada na home
- [x] 0044: Simulador com a tabela projetada no lugar da atual e "Zerar simulação"
- [x] 0045: fuso do app em Brasília ("hoje", horários exibidos e datas do CSV)
- [x] 0046: scroll snap da home por proximidade
- [x] 0047: classificação no card de campeonato da home
- [x] 0048: jogos de hoje numa faixa horizontal única
- [x] 0049: jogos de hoje em faixa sem fim
- [x] 0050: jogos de hoje sem barra de rolagem
- [x] 0051: jogos de hoje com cards inteiros e passo de um card
- [x] 0052: scouts no seed demo
- [x] 0053: Esquadrão só com jogadores do campeonato
- [x] 0054: Top 3 Bolão e Esquadrão no seed dos campeonatos
- [x] 0055: "Como funciona" logo depois dos módulos
- [ ] Backlog: salvar/compartilhar simulação, Monte Carlo da temporada, oferta e demanda na valorização do Esquadrão

Estado de cada fase: [STATUS](docs/checkpoints/STATUS.md).

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

## Contribuindo

1. Faça um fork do projeto
2. Crie uma branch (`git checkout -b feat/minha-feature`)
3. Faça commits assinados (`git commit -S -m 'feat: minha feature'`)
4. Abra um Pull Request

Rode `bin/ci` antes do PR. Agentes seguem [docs/agents.md](docs/agents.md); ferramentas e padrões de código: [docs/QUALITY.md](docs/QUALITY.md).

## Licença

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE).

## Contato

Lucas Mafra Chagas — [@LMafra](https://github.com/LMafra)

Projeto: [github.com/LMafra/futebol](https://github.com/LMafra/futebol)

## Agradecimentos

- [Best-README-Template](https://github.com/othneildrew/Best-README-Template)
- [Rails Engines](https://guides.rubyonrails.org/engines.html)
- [Packwerk](https://github.com/Shopify/packwerk)
- [ActiveAdmin](https://activeadmin.info)
- [Shields.io](https://shields.io)

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

<!-- Links de referência -->
[ci-shield]: https://github.com/LMafra/futebol/actions/workflows/ci.yml/badge.svg
[ci-url]: https://github.com/LMafra/futebol/actions/workflows/ci.yml
[ruby-shield]: https://img.shields.io/badge/Ruby-3.3-CC342D?logo=ruby&logoColor=white
[rails-shield]: https://img.shields.io/badge/Rails-8.1-D30001?logo=rubyonrails&logoColor=white
[license-shield]: https://img.shields.io/badge/License-MIT-0B6B3A
[license-url]: LICENSE
[ruby-badge]: https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white
[ruby-url]: https://www.ruby-lang.org
[rails-badge]: https://img.shields.io/badge/Rails-D30001?style=for-the-badge&logo=rubyonrails&logoColor=white
[rails-url]: https://rubyonrails.org
[supabase-badge]: https://img.shields.io/badge/PostgreSQL_%28Supabase%29-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white
[supabase-url]: https://supabase.com
[solid-queue-badge]: https://img.shields.io/badge/Solid_Queue-4A4A45?style=for-the-badge
[solid-queue-url]: https://github.com/rails/solid_queue
[activeadmin-badge]: https://img.shields.io/badge/ActiveAdmin-161616?style=for-the-badge
[activeadmin-url]: https://activeadmin.info
[view-component-badge]: https://img.shields.io/badge/ViewComponent-0B6B3A?style=for-the-badge
[view-component-url]: https://viewcomponent.org
[tailwind-badge]: https://img.shields.io/badge/Tailwind_CSS-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white
[tailwind-url]: https://tailwindcss.com
[openobserve-badge]: https://img.shields.io/badge/OpenObserve-E85D04?style=for-the-badge
[openobserve-url]: https://openobserve.ai
[render-badge]: https://img.shields.io/badge/Render-000000?style=for-the-badge&logo=render&logoColor=white
[render-url]: https://render.com
