# Listagens

Como mostrar uma lista no Craquefy: Admin, Gestor e site público usam o mesmo componente, `Ui::CollectionComponent`, e o mesmo vocabulário.

## Regras
- **Celular:** toda tabela vira cartões empilhados abaixo de 768px. A coluna principal (`primary: true`) vira o título do cartão; as outras viram pares rótulo/valor (`mobile_label:` encurta o rótulo).
- **Alvos de toque:** linhas, links e caixas de seleção com pelo menos 48px de altura. Não existe modo compacto.
- **Alternar visualização** só quando a tarefa muda: Times (Grade ↔ Tabela) e Partidas (Por rodada ↔ Agenda).
  - A escolha fica na URL (`?view=`), então o link compartilhado abre igual.
  - A última escolha é lembrada por listagem no navegador. Quem abre a listagem sem `?view=` volta para ela.
- **Ordenar:** só colunas com `sortable: true`. O cabeçalho é um link sublinhado (`?sort=&dir=`) e marca `aria-sort`. No celular, os mesmos links aparecem em "Ordenar por". Quem ordena os itens é o controller; o componente só monta os links.
- **Buscar:** por nome, mais selects simples (TICKET-0088).
- **Selecionar em lote:** cada item tem uma caixa ligada ao formulário da barra de ações, que fica fixa no rodapé enquanto houver seleção. Ações destrutivas pedem confirmação. Sem JavaScript, a barra fica sempre visível.
- **Lista vazia:** diz o que falta e oferece a ação de criar (`c.empty { … }` com `Ui::EmptyStateComponent`).
- **Tudo funciona sem JavaScript:** visualização, ordenação e mestre-detalhe são links; o JavaScript (`collection_controller.js`) só lembra a visualização e conta a seleção.

## Modos

| Modo | Quando usar | Exemplos |
| --- | --- | --- |
| `table` | Comparar valores entre itens | Jogadores, usuários, CSV, classificação |
| `cards` | Itens com poucos dados e uma ação principal | Campeonatos, bolões |
| `grid` | Reconhecer pela imagem | Times (escudo) |
| `grouped` | Muitos itens com um agrupador natural; só o grupo atual aberto | Partidas por rodada |
| `agenda` | Itens no tempo, para planejar | Partidas por dia |
| `master_detail` | Escolher um item e ver os detalhes ao lado (`?item=ID`); no celular, a lista e depois o item | Participantes do Bolão e do Esquadrão |
| `timeline` | Histórico | Auditoria, lances da partida |

## Uso

```erb
<%= render Ui::CollectionComponent.new(items: @teams, id: "teams", views: { grid: "Grade", table: "Tabela" },
                                       view: params[:view], sort: params[:sort], direction: params[:dir],
                                       texts: { label: "Times" }) do |c| %>
  <% c.column(:crest, label: "Escudo", media: true) { |team| team_crest(team) } %>
  <% c.column(:name, label: "Nome", primary: true, sortable: true) { |team| link_to team, team_path(team) } %>
  <% c.column(:players_count, label: "Jogadores", numeric: true, sortable: true) %>
  <% c.empty { render Ui::EmptyStateComponent.new(title: "Nenhum time ainda") } %>
<% end %>
```

### No Admin e no Gestor

Os índices do ActiveAdmin usam o renderizador `AdminCollectionIndex`. Filtros, escopos, paginação e downloads continuam do ActiveAdmin; a lista vem de um parcial em `app/views/admin/listings/`, que recebe `records` (a página atual) e `namespace` (`:admin` ou `:gestor`).

```ruby
ActiveAdmin.register Core::Team, namespace: :gestor do
  AdminCollectionIndex.register(self, 'admin/listings/teams')
end
```

- `?sort=&dir=` vira o `order` do ActiveAdmin (`CollectionSortParams`), só para colunas da tabela.
- Contagens por linha vêm de `listing_counts(Modelo, :chave, records)`: uma consulta por contagem.
- A seleção em lote do ActiveAdmin fica desligada nessas telas; ações em lote usam `c.bulk_action`.
- Auditoria da migração: `docs/checkpoints/UX-LISTAGENS.md`.
