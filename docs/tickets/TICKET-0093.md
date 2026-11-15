# TICKET-0093 — Bolão criado só pelo Gestor ou Admin

- Deps: TICKET-0090, TICKET-0092
- Skill: [W]tdd, migration
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 ([ADR 0006](../adr/0006-gestor-times-lances.md), Bolão)

## Descrição
- **Qualquer um criava:** todo usuário logado via "Criar bolão" no site público e escolhia qualquer campeonato. O gestor não controlava os bolões do próprio campeonato.
- **Criador participante:** quem criava entrava como participante e aparecia como "Dono" na lista de membros.
- **Sem caminho no Gestor:** o Gestor só listava os bolões, sem criar.

## Ambiente
- Celular 390px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Usuário (`demo1@demo.local`) e Gestor (`gestor@demo.local`)

## Severidade
Média: bolões fora do controle do gestor, em campeonatos de outros.

## Passos para reproduzir
1. Entrar como usuário comum e abrir `/pools`.
2. Clicar em "Criar bolão" e escolher qualquer campeonato.

## Esperado
Só o gestor do campeonato, ou o Admin, cria bolões. O usuário entra pelo código.

## Atual
O bolão é criado, e o usuário vira dono.

## Correção
- **Permissão:** `Bolao::PoolPolicy#create?` vale só para o Admin e para o Gestor no próprio campeonato.
- **Site público:**
  - saem a rota, a tela e o componente de criação (`Pools::NewComponent`);
  - `/pools` explica que o gestor cria os bolões e que o código vem dele;
  - a página do bolão mostra "Organizado por …" no lugar da marca "Dono".
- **Gestor:**
  - "Criar bolão" na página do campeonato abre o formulário com o campeonato já escolhido;
  - o formulário lista só os campeonatos do gestor;
  - ao criar, o aviso traz o código para compartilhar;
  - a página do bolão mostra o código e o número de participantes.
- **Admin:**
  - "Criar bolão" na página do campeonato;
  - o organizador vem preenchido com o gestor do campeonato ou com o próprio admin.
- **Organizador não participa:** o bolão não adiciona mais o dono como membro.
- **Migração `TransferBolaoPoolsToManagers`** (`Bolao::PoolOwnershipTransfer`):
  - cada bolão passa para o gestor do campeonato, e o dono antigo continua membro (é incluído se não era);
  - sem gestor, o dono continua o mesmo;
  - o `down` devolve o bolão ao membro mais antigo que não é o gestor.
- **Seeds:** os bolões de demonstração são do gestor do campeonato, ou de um admin.

## Evidência
- `spec/policies/bolao/pool_policy_spec.rb`, `spec/requests/gestor/pools_spec.rb`, `spec/requests/bolao/pools_spec.rb`, `spec/data_migrations/pool_ownership_transfer_spec.rb`, `spec/components/pools/show_component_spec.rb`, `spec/seeds_spec.rb`
- Playwright 390px: o gestor cria o bolão pela página do campeonato e recebe o código; `/pools` sem "Criar bolão" para o usuário

## Pronto quando
- [x] Só Gestor (no próprio campeonato) e Admin criam bolões
- [x] Criação no Gestor a partir da página do campeonato
- [x] Bolões existentes transferidos ao gestor, com o dono antigo como membro
