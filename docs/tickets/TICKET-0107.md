# TICKET-0107 — Interface só em português

- Deps: TICKET-0106
- Skill: [W]tdd
- MCP: playwright
- Origem: revisão do PR #87 (2026-11-14)

## Descrição
A interface misturava termos em inglês com o português:
- "Status" no cabeçalho das filas e nos atributos;
- "Preview do Bolão" no Admin;
- "Logs de auditoria" no menu e no título;
- "Scout(s)" para o acontecimento e para o total do jogador ("Aguardando scouts", "Scouts de Fulano", "Nenhum scout lançado ainda");
- "Ranking" no público, no Esquadrão e nos participantes.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Visitante, usuário, Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`)

## Severidade
Baixa: nada quebrava, mas o produto falava duas línguas e os termos do glossário não chegavam à tela.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor`.
2. Ler o indicador "Aguardando scouts" e a coluna "Status" da fila de partidas.
3. Abrir a home e ler "Ranking de atletas".

## Esperado
Português em todo texto visível: "Aguardando lances", "Situação", "Classificação de atletas".

## Atual
Termos em inglês (`docs/checkpoints/ux-audit/before-0107/`).

## Correção
| Antes | Depois |
| --- | --- |
| Status | Situação |
| Preview do Bolão, Calcular preview | Prévia do Bolão, Calcular prévia |
| Log(s) de auditoria, Log de erros | Registro(s) de auditoria, Registro de erros |
| Scout(s), para o acontecimento | Lance(s): "Aguardando lances", "Registre os lances antes de finalizar", "Lances de Fulano" |
| Scout(s), para o total do jogador | Estatísticas: "Nenhuma estatística lançada ainda", "Legenda das estatísticas", "Esquadrão: estatísticas do jogador" |
| Ranking(s) | Classificação: "Classificação do Bolão", "Classificação de atletas", "Ver classificação do Bolão" |

- **Glossário:** Scout virou nome interno, e o termo de interface é Estatísticas. Entraram Classificação, Situação, Prévia e Registro de auditoria, e a lista do que fica em inglês: E-mail, CSV e PWA.
- **Código intacto:** rotas, classes e colunas continuam com os nomes internos (`/esquadrao/rankings`, `Cartola::ScoutEvent`, `status`).
- **Spec de design** (`spec/design/portuguese_spec.rb`): falha se Status, Preview, Scout, Ranking ou Log voltarem ao texto visível. Ele lê:
  - o texto e os atributos visíveis (`aria-label`, `title`, `placeholder`, `alt`) dos templates, compilados com Erubi e lidos com Ripper;
  - os rótulos e as mensagens em Ruby (admin, componentes, controllers, forms, helpers, serviços);
  - os valores dos locales.
  
  Ignora identificadores, classes, `data-*`, SQL e mensagens de exceção.

## Evidência
- `spec/design/portuguese_spec.rb`: templates, Ruby e locales.
- Specs atualizados com os textos novos: painel do Gestor, tela da partida, home, participantes do bolão, classificação do Esquadrão, consistência do Admin, usuários e links.
- Varredura no navegador (`tmp/pw/sweep0107.js`):
  - 125 páginas, como visitante (12), Admin (53), Gestor (24) e usuário logado (36);
  - segue os links internos e procura os termos no texto visível, em `aria-label`, `title` e `placeholder`;
  - nenhuma ocorrência.
- Screenshots: `docs/checkpoints/ux-audit/before-0107/` e `after-0107/`.

## Pronto quando
- [x] Situação, Prévia do Bolão, Registros de auditoria, Lances, Estatísticas e Classificação em todo texto visível
- [x] Glossário atualizado (Scout como nome interno)
- [x] Spec de design que falha se os termos em inglês voltarem
- [x] E-mail, CSV e PWA mantidos
