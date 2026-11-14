# TICKET-0106 — Links x botões: guia, helper e revisão dos rótulos

- Deps: TICKET-0083, TICKET-0084
- Skill: [W]tdd, ui-ux-pro-max
- MCP: —
- Origem: pedido de revisão dos links de redirecionamento (2026-11-12), com base na literatura de UX sobre links e botões

## Descrição
Os links de navegação não seguiam um padrão:
- **Sublinhado só no hover:** títulos de card, links das tabelas do painel do Admin, rodapé e breadcrumbs do Admin, nome do bolão na lista. No celular, onde não há hover, esses links pareciam texto comum.
- **Estilo repetido à mão:** cada tela escrevia o próprio estilo de link (`underline underline-offset-2 hover:no-underline`, com variações).
- **Rótulos vagos:**
  - "Ver" no ícone de toda linha das tabelas do Gestor, com o mesmo rótulo em todas as linhas para o leitor de tela;
  - "Ver" no botão do filtro de rankings;
  - "Crie o primeiro" no painel vazio do Gestor;
  - "Ver log" na classificação com erro;
  - "nesta página" no e-mail de redefinição de senha.
- **"Sair" no cabeçalho:** é uma ação, mas tinha aparência de link que só sublinhava no hover.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Visitante, usuário (`demo1@demo.local`), gestor (`gestor@demo.local`) e admin (`admin@futebol.dev`)

## Severidade
Média: links sem sinalização visual e rótulos vagos prejudicam a navegação no celular e com leitor de tela (WCAG 1.4.1 e 2.4.4).

## Passos para reproduzir
1. Abrir `/` no celular e procurar o link no nome de um campeonato.
2. Abrir `/gestor/teams` com um leitor de tela e percorrer os ícones das linhas.
3. Abrir `/esquadrao/rankings` com mais de um campeonato.

## Esperado
Todo link de texto sublinhado em repouso, com rótulo que diz o destino. Ações são botões.

## Atual
Nomes de campeonato sem sublinhado, ícones "Ver" repetidos, botão "Ver".

## Correção
- **Guia** [docs/ux/links-e-botoes.md](../ux/links-e-botoes.md):
  - cinco papéis: link inline, link de apoio, CTA, botão de ação e ícone-link;
  - regras de sinalização, microcopia e CTA primário único (com exceção para filas de trabalho);
  - estados: padrão, hover, foco, visitado e desabilitado.
- **`LinkClassesHelper`**, incluído em `Ui::BaseComponent` e lido pelo Tailwind do Admin:
  - `inline_link_classes(tone: :pitch | :ink)`;
  - `title_link_classes`, que mantém a fonte do título;
  - `support_link_classes`.
  - Os links de texto do público, do Admin e do Gestor passam a usar o helper.
- **`admin_icon_action_link(verbo, href, ícone, subject:)`:** o rótulo acessível e o `title` levam verbo e registro, por exemplo "Abrir Real Paraisópolis".
  - Aplicado no partial padrão de ações do ActiveAdmin ("Abrir", "Editar" e "Excluir" + `display_name`) e nas tabelas do Gestor.
  - O Preview da lista de partidas do Admin vira "Preview do Bolão de <partida>".
- **Rótulos corrigidos:**
  - "Mostrar ranking" no filtro de rankings, no público e no Admin;
  - "Criar campeonato" no painel vazio do Gestor;
  - "Abrir o registro do erro" na classificação com erro;
  - "Preview do Bolão" na tabela "Ao vivo" do painel do Admin;
  - "Tabela do campeonato" e "Rankings do campeonato" no público;
  - "Redefinir minha senha" no e-mail de redefinição.
- **Cabeçalho público:** "Sair" vira botão com contorno, igual ao "Entrar". O gatilho "Minha conta" ganha fundo no hover em vez do sublinhado.
- Links soltos que a navegação estrutural futura (0094) vai cobrir continuam como link inline ou de apoio.

## Evidência
- Navegador (Playwright):
  - `/` em 390px com "Sair" como botão;
  - `/gestor` com os nomes das partidas sublinhados;
  - `/gestor/teams` com os rótulos "Abrir Real Paraisópolis" e "Editar Real Paraisópolis".
- `spec/design/links_spec.rb` varre views, components, admin e helpers. Falha com rótulo vago em `link_to`/`button_to`/`submit_tag`/`submit`/`admin_icon_action_link`/`<button>`, e com `hover:underline` (exceto `group-hover` em card clicável).
- `spec/requests/links_spec.rb` e `spec/helpers/link_classes_helper_spec.rb`; `consistency_spec` e `simulador_spec` atualizados.

## Pronto quando
- Nenhum link de texto sublinhado só no hover
- Nenhum rótulo vago
- Gate `test` verde
