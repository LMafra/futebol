# TICKET-0101 — PWA instalável, menu inferior no Admin/Gestor e revisão em 390px

- Deps: TICKET-0094, TICKET-0097
- Skill: [W]tdd
- MCP: playwright (instalação, offline e telas em 390px)
- Origem: rodada de ajustes de 2026-11-12 (fase 6, celular), ADR 0006

## Descrição
- **Não instalável:** o Craquefy não podia ser instalado no celular.
  - As rotas `manifest` e `service-worker` estavam comentadas em `config/routes.rb`.
  - O manifest tinha `theme_color: red`.
  - Os ícones eram o círculo vermelho do gerador do Rails.
- **Navegação no celular:** no Admin e no Gestor, a navegação só existia no menu lateral, aberto pelo botão do topo. Para trocar de seção era preciso abrir o menu toda vez.

## Ambiente
- Rails 8.1 (`Rails::PwaController`), importmap, ActiveAdmin 4 com Flowbite (drawer)
- Chromium 1208 (Playwright) em 390×844 com toque, e em 1280×900

## Severidade
Média: o gestor registra lances na beira do campo, pelo celular.

## Passos para reproduzir
1. Abrir o site no celular e procurar "Instalar app".
2. Entrar no Gestor em 390px e trocar de Campeonatos para Participantes.

## Esperado
- O site instala, com ícone e cor da marca. Sem conexão, mostra uma página própria.
- No Gestor, um menu inferior com as seções.

## Atual
- Não instalava.
- Trocar de seção pedia abrir o menu lateral.

## Correção
- **Manifest** (`app/views/pwa/manifest.json.erb`):
  - nome e descrição da marca, `display: standalone`;
  - `theme_color` `#0B6B3A` (pitch) e `background_color` `#F4F1EA` (paper);
  - ícones 192, 512, maskable 512 e SVG;
  - atalhos para Meus bolões e Gestor.
- **Ícones** (`public/icon.svg`, `icon-maskable.svg`, PNGs gerados a partir deles): "C" com a bola, no verde da marca. O maskable tem margem de segurança; o `apple-touch-icon` vem sem transparência.
- **Service worker** (`app/views/pwa/service-worker.js`, registrado por `pwa.js` nos dois layouts):
  - as páginas vêm sempre da rede, porque placar e lances são ao vivo;
  - se a navegação falha, responde com `public/offline.html`, guardada na instalação;
  - nada mais é cacheado.
- **Layouts:** `layouts/_pwa_head` liga o manifest, `theme-color` e os ícones no site público e no Admin/Gestor.
- **Menu inferior** (`active_admin/_bottom_nav`), abaixo de 640px no Admin e no Gestor:
  - as quatro primeiras seções do menu lateral (Painel, Campeonatos, Times, Participantes), com ícone e a seção atual marcada (`aria-current`);
  - "Mais" abre o menu lateral completo;
  - o conteúdo ganha espaço embaixo;
  - o rodapé fixo de Finalizar da partida fica acima do menu.
- **Ícone de Painel** no Admin ("Painel Administrativo"), que faltava também no menu lateral.
- **Revisão em 390px** (Playwright): home, partida pública, painel, campeonatos, partida, bolão, Esquadrão e times do Gestor, sem rolagem lateral.
  - A fila de partidas do painel ainda é tabela com rolagem interna.
  - Ela vira cards na TICKET-0103, junto com as outras listagens.

## Evidência
- `spec/requests/pwa_spec.rb`:
  - manifest com cores, ícones existentes e `standalone`;
  - service worker com a página offline;
  - links no layout público;
  - manifest e menu inferior no Gestor, com a seção atual e "Mais".
- Playwright (`tmp/pw/pwa0101.js`, `tmp/pw/finalize0101.js`):
  - manifest lido e service worker ativo;
  - offline, a navegação mostra "Você está sem conexão";
  - menu inferior visível em 390px e oculto em 1280px; "Mais" abre o menu lateral;
  - o rodapé de Finalizar termina onde o menu começa;
  - sem rolagem lateral nas telas revisadas.

## Pronto quando
- [x] Rotas `manifest`/`service-worker`, ícones, `theme_color` e página offline
- [x] Menu inferior no Admin/Gestor em menos de 640px
- [x] Revisão em 390px
