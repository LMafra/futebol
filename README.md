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

  <h3 align="center">Futebol</h3>

  <p align="center">
    Bolão, Cartola e Simulador em um monólito modular Rails 8.
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

Plataforma Rails 8 com engines `core`, `bolao`, `cartola` e `simulador` para quem acompanha o campeonato com os amigos: no **Bolão**, cada participante palpita o placar das partidas de um grupo; no **Cartola**, monta a escalação da rodada com os limites por posição do campeonato e compra os jogadores com a carteira de cartoletas; o **Simulador** projeta a classificação ("e se") a partir de placares hipotéticos, aberto a visitantes ([ADR 0003](docs/adr/0003-simulador.md)). Partidas, times e usuários vivem no `core`; o admin cadastra, importa e finaliza partidas, e a pontuação é calculada por jobs.

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

Infra: Render + Supabase (Postgres) + R2 + Resend + OpenObserve ([MCPs](docs/mcp/README.md)). Em produção: [futebol-web.onrender.com](https://futebol-web.onrender.com) no Render (plano free, Ohio) com Postgres no Supabase (`sa-east-1`).

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

O web service `futebol-web` roda o [`Dockerfile`](Dockerfile) no Render; o `bin/docker-entrypoint` aplica as migrations (`db:prepare`) no boot pelo session pooler do Supabase (porta 5432), e o app usa o transaction pooler (porta 6543). Sem worker no plano free: o Solid Queue roda dentro do Puma (`SOLID_QUEUE_IN_PUMA=1`). O serviço não faz auto-deploy; dispare pelo Dashboard (Manual Deploy) ou pelo MCP do Render (`trigger_deploy`).

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://futebol-web.onrender.com/up   # 200
```

No free tier, o Render hiberna o web após 15 min sem tráfego, e o Supabase pausa o projeto após 7 dias sem atividade. Variáveis, poolers, retomada do projeto e passos ainda manuais: [OPERATIONS.md → Deploy](docs/OPERATIONS.md#deploy-render--supabase).

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

## Infraestrutura de produção

As variáveis ficam documentadas em [`.env.example`](.env.example) e, em produção, no grupo `futebol` do Render. Nenhum valor real entra no repositório.

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

Passo manual: o R2 ainda precisa ser habilitado no Dashboard da Cloudflare antes da criação dos buckets ([OPERATIONS.md → Storage](docs/OPERATIONS.md#storage-cloudflare-r2)).

### Resend

Production envia e-mail pelo SMTP do Resend ([`config/environments/production.rb`](config/environments/production.rb)): `smtp.resend.com`, porta 465 com TLS, usuário `resend` e a API key como senha.

1. Crie a conta em [resend.com](https://resend.com) e gere uma API key (`re_xxxxxxxxx`) com permissão Sending access.
2. Em Domains, cadastre e verifique o domínio do remetente (registros SPF/DKIM no DNS). Sem isso, `onboarding@resend.dev` só entrega para o e-mail do dono da conta.
3. No Render (env vars do `futebol-web`), defina `RESEND_API_KEY` e `RESEND_FROM` (ex.: `Futebol <bolao@seu-dominio.com>`).

Teste de envio e detalhes: [OPERATIONS.md → E-mail](docs/OPERATIONS.md#e-mail-resend).

<p align="right">(<a href="#readme-top">voltar ao topo</a>)</p>

## Uso

1. **Campeonato:** em [`/admin`](http://localhost:3000/admin), cadastre o campeonato e os times (Cadastros) e importe as partidas por CSV (Cadastros → Importações CSV).
2. **Bolão:** crie um bolão em [`/pools/new`](http://localhost:3000/pools/new) e compartilhe o código; os amigos entram por [`/pools`](http://localhost:3000/pools).
3. **Palpites:** cada participante palpita o placar das partidas na página de palpites do bolão.
4. **Escalação:** monte o time da rodada no Cartola em [`/lineup`](http://localhost:3000/lineup) e acompanhe os rankings em [`/cartola/rankings`](http://localhost:3000/cartola/rankings).
5. **Finalizar partida:** no admin, Pontuação → Finalizar partida confirma o placar; o job pontua palpites e escalações (Pontuação → Reverter pontuação desfaz).

Login demo (só development/test, criado pelo `db:seed`): `demo1@demo.local` … `demo5@demo.local` / `demo-futebol` e o admin `admin@futebol.dev` / `futebol-admin`, com o bolão `DEMO01` já pontuado. Detalhes dos dados demo, filas e comandos: [docs/OPERATIONS.md](docs/OPERATIONS.md).

Em produção não há contas demo, porque a senha acima é pública: o seed cria só o admin, com senha forte guardada fora do repositório, além de times, jogadores e partidas. Novas contas saem do cadastro público em [`/signup`](http://localhost:3000/signup) (link "Criar conta" no login); ainda não há tela de usuários no admin.

## Roadmap

Escopo e contratos em [spec v3](docs/spec-v3.md); trabalho em 31 tickets ([INDEX](docs/tickets/INDEX.md)).

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
- [ ] Pendências de produção: R2, Resend, host do OpenObserve self-hosted, `RENDER_DEPLOY_HOOK_URL` e keep-alive (manual)
- [x] 0031: Simulador v1 "e se" em [`/simulador`](http://localhost:3000/simulador) (ADR 0003, que o numerava 0029; `core_matches.round` entrou no 0030)
- [ ] Backlog: salvar/compartilhar simulação, Monte Carlo da temporada

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
