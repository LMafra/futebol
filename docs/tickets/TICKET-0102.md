# TICKET-0102 — Componente único de listagens

- Deps: TICKET-0088, TICKET-0106
- Skill: [W]tdd
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 (grill de listagens)

## Descrição
- **Uma tabela para tudo:** cada listagem do Admin, do Gestor e do site público montava a própria tabela.
- **Celular:** no celular, as tabelas largas rolavam para o lado.
- **Sem alternativas:** não havia como ver por grade, agrupar por rodada ou abrir os detalhes ao lado.
- **Sem seleção em lote.**

## Ambiente
- Celular 390px e desktop 1024px, Chromium 1208 (Playwright), previews do ViewComponent (`/rails/view_components/ui/collection_component/default`)

## Severidade
Média: as listagens do celular eram difíceis de ler, e as telas das fases seguintes precisariam repetir o mesmo trabalho.

## Passos para reproduzir
1. Abrir `/gestor/teams` em 390px.
2. Rolar a tabela para o lado para ver as colunas.

## Esperado
A lista vira cartões no celular, com a mesma ordenação, visualização e seleção em todas as telas.

## Atual
Tabela com rolagem horizontal, diferente em cada tela.

## Correção
- **`Ui::CollectionComponent`:**
  - Modos `table`, `cards`, `grid`, `grouped` (sanfona), `agenda`, `master_detail` e `timeline`.
  - Colunas declaradas uma vez, com `primary:`, `mobile_label:`, `sortable:`, `numeric:` e `media:`.
  - Abaixo de 768px, a tabela vira cartões empilhados: a coluna principal vira o título (`th scope="row"`), e as demais viram rótulo/valor (`data-label`).
  - Cabeçalhos ordenáveis são links (`?sort=&dir=`) com `aria-sort`, repetidos em "Ordenar por" no celular.
  - Alternância de visualização (`?view=`) com `aria-current`.
  - Mestre-detalhe por `?item=ID`; no celular, a lista e depois o item, com "Voltar para a lista".
  - Barra de seleção em lote com ações por `formaction` e confirmação nas destrutivas.
  - Estados padrão, carregando, vazio (com conteúdo próprio, como um CTA) e erro.
- **`collection_controller.js`** (público e Admin/Gestor):
  - lembra a visualização escolhida por listagem no `localStorage` e volta para ela quando a URL não traz `?view=`;
  - conta a seleção, esconde a barra sem seleção e controla "Selecionar todos" (com estado indeterminado).
- **Guia `docs/ux/listagens.md`:** a regra do celular e qual modo usar em cada listagem.
- A migração das telas para o componente fica no TICKET-0103.

## Evidência
- `spec/components/ui/collection_component_spec.rb` e preview com os quatro estados
- Playwright: tabela em cartões no 390px com seleção; tabela ordenável no 1024px; sanfona, mestre-detalhe e linha do tempo

## Pronto quando
- [x] Sete modos com a mesma declaração de colunas
- [x] Tabela vira cartões abaixo de 768px
- [x] Visualização e ordenação por URL; visualização lembrada; seleção em lote
