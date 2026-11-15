# Links e botões

Guia de uso, microcopia e estados para links e botões no público, no Admin e no Gestor. Complementa os tokens de `docs/design/` (Placar de Domingo) e os helpers `ButtonClassesHelper`, `LinkClassesHelper`, `AdminHelper` e `AdminIconsHelper`.

Regra de base: **link navega, botão age.** Um link leva a outro conteúdo (outra página, outra aba, outro trecho). Um botão executa algo (salvar, enviar, excluir, alternar). Quando a navegação é a ação principal da tela, o link ganha cara de botão (CTA), mas continua sendo `<a>`.

## Os cinco papéis

| Papel | Quando usar | Elemento | Classes |
|---|---|---|---|
| Link inline | Dentro de uma frase ou de um card, para detalhes ou conteúdo relacionado | `<a>` | `inline_link_classes` (título de card ou linha: `title_link_classes`, que mantém a fonte do título) |
| Link de apoio | Navegação secundária: voltar, cancelar, "esqueceu a senha?", rodapé, termos | `<a>` | `support_link_classes` (rodapé: `footer_link`) |
| CTA | A navegação é o objetivo da tela: "Criar bolão", "Entrar", "Ir para a finalização" | `<a>` com cara de botão | `primary_button_classes` / `secondary_button_classes` (Admin: `ADMIN_BUTTON_CLASSES` / `ADMIN_SECONDARY_BUTTON_CLASSES`) |
| Botão de ação | Salvar, enviar, filtrar, excluir, mostrar senha; nunca navega para outra página por si só | `<button>` / `button_to` / `submit` | papéis `primary`, `secondary`, `danger` |
| Ícone-link | Ações por linha nas tabelas (abrir, editar, excluir) | `<a>` 40px com ícone | `admin_icon_action_link(verbo, href, ícone, subject:)` |

Navegação estrutural (onde estou, para onde posso ir) não é link solto: fica no menu, nas abas (`tab_link_classes`, `aria-current="page"`) ou nos breadcrumbs. Um link solto que repete o menu pode continuar na tela, mas como link de apoio.

## Regras

1. **Sinalização visual.** Link de texto é sempre sublinhado em repouso (`underline underline-offset-2`), mais cor ou peso. Nunca só cor, nunca sublinhado só no hover. Exceções: CTA (já tem forma de botão), ícone-link (tem borda e ícone), item de menu, aba e card inteiro clicável (a forma do card sinaliza).
2. **Microcopia que diz o destino.** O texto do link descreve onde se chega: "Voltar para meus bolões", "Abrir os scouts da partida", "Tabela completa".
   - Proibidos como texto inteiro do link ou do botão: "Ver", "clique aqui", "aqui", "saiba mais", "nesta página", "Crie o primeiro".
   - Ícone-link: o rótulo acessível (`aria-label` e `title`) leva verbo e objeto ("Abrir Real Paraisópolis", "Editar Copa da Vila").
3. **No máximo um CTA primário por tela.** Os demais CTAs são secondary. Ação destrutiva é danger. Exceção: filas de trabalho (a fila de partidas do Gestor, TICKET-0076), em que cada linha mostra o próximo passo como a única ação primária daquela linha.
4. **Botão não navega, link não age.** Excluir, aprovar, finalizar com efeito colateral são `button_to`/formulário, nunca `link_to` com `method:`. Exceção herdada: o link de excluir comentário do ActiveAdmin.
5. **Custo da troca de contexto.** Antes de levar o usuário para outra tela, prefira resolver no lugar (modal, seção recolhida). Quando levar, o rótulo antecipa o destino.

## Estados

| Estado | Link inline / apoio | CTA e botões |
|---|---|---|
| Padrão | sublinhado, `text-pitch` (público) ou `text-ink` (Admin), `font-semibold` no inline | fundo do papel (`bg-cartola`, borda `graphite`, `bg-loss-solid`) |
| Hover | tira o sublinhado (`hover:no-underline`); o apoio escurece para `ink` | inverte para `bg-ink text-white` (público) ou escurece (Admin) |
| Foco | anel global `:focus-visible` (`outline-ink`; branco sobre `pitch`/`night`) | o mesmo anel |
| Visitado | igual ao padrão: no produto, o histórico de visita não ajuda a decidir | — |
| Desabilitado | link não desabilita: some ou vira texto com o motivo | `disabled:opacity-60`, `cursor-not-allowed`, motivo ao lado |

Alvos de toque: 48px no público (`min-h-12`), 40px no Admin. Link inline dentro de frase fica com a altura da linha; se for o único caminho da tela, vira CTA.

## Verificação

`spec/design/links_spec.rb` varre `app/views`, `app/components`, `app/admin` e `app/helpers` e falha com:
- rótulo vago (lista da regra 2) em `link_to`, `button_to`, `submit_tag`, `submit` e `admin_icon_action_link`;
- classe `hover:underline` (sublinhado só no hover). `group-hover:underline` dentro de um card inteiro clicável é permitido.
