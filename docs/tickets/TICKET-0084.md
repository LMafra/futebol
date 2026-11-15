# TICKET-0084 — Consistência do Admin/Gestor: tradução, papéis de botão, CSV e formulários

- Deps: TICKET-0081, TICKET-0077
- Skill: [W]tdd, ui-ux-pro-max
- MCP: —
- Origem: auditoria UI/UX completa (2026-11-12)

## Descrição
O Admin e o Gestor misturavam inglês cru, rótulos vagos e papéis de botão iguais:
- **Status e atributos sem tradução:**
  - Os filtros de status mostravam `scheduled`, `finished`, `pending`, `admin`…
  - O seletor de partida mostrava `· finished ·`, e o Preview do Bolão dizia "A partida está finished".
  - Os cabeçalhos mostravam "Match date", "Scores calculated at", "Rows processed", "Email address", "Owner", "Crest url"…
  - Os prêmios saíam como "First place".
- **KPI "Pendentes de finalização"** levava para a tela de finalizar (partidas ao vivo), mas contava partidas encerradas sem pontuação. **"Campeonatos ativos"** contava todos os campeonatos.
- **Preview do Bolão:** o CTA "Confirmar este placar na finalização" passava o placar simulado, mas a finalização usa o placar dos scouts.
- **Show da partida:** Preview, Scouts, Finalizar, Reverter e Histórico eram todos botões laranja (primários). Reverter, que é destrutivo, não se distinguia.
- **Ações de linha do Gestor:** links de texto "Ver"/"Editar" em Regras do Bolão, Escalações, Jogadores, Bolões e Times, diferentes dos ícones de 40px usados em Partidas e Campeonatos.
- **Importação CSV:**
  - O legend do fieldset era a lista técnica de colunas.
  - O status saía cru (`completed`), e o show não usava `Ui::CsvImportStatusComponent`.
- **Formulários:**
  - O erro da confirmação do placar não ficava ligado ao campo.
  - O marcador de obrigatório variava (`*` no Formtastic, "(obrigatório)" em alguns rótulos, nada no preview).
  - A data da partida do Gestor usava 5 selects.
  - O comentário não tinha rótulo, e as colunas numéricas ficavam à esquerda.
- **Termos:**
  - O menu do Admin dizia "Meus campeonatos", mas o Admin vê todos.
  - O link do formulário dizia "Pontuação do Bolão", e o menu, "Regras do Bolão".
  - Os cards do Gestor tinham os links vagos "Partida" e "Editar".
- **Estados vazios:** `<p>` soltos no dashboard, nos rankings do Esquadrão e no preview.

## Ambiente
- Desktop 1440px, Chromium 1208 (Playwright), Rails 8.1 dev local, ActiveAdmin 4.0.0.beta23
- Usuários: admin (`admin@futebol.dev`) e gestor (`gestor@demo.local`)

## Severidade
Média: confunde a operação (KPI com destino errado, CTA que sugere usar o placar simulado, ação destrutiva com cara de primária), mas não bloqueia.

## Passos para reproduzir
1. Abrir `/admin/matches` e o filtro Status.
2. Abrir `/admin` e clicar em "Pendentes de finalização".
3. Abrir `/admin/matches/<partida ao vivo>`.
4. Abrir `/gestor/players`.
5. Abrir `/admin/csv_imports/new`.

## Esperado
- Status e atributos em português.
- O KPI leva às partidas encerradas sem pontuação.
- O show da partida tem uma ação primária, e Reverter é danger.
- O Gestor usa os mesmos ícones de linha que o resto do painel.

## Atual
- `finished`/`Match date` crus.
- O KPI abre a tela de finalizar.
- Cinco botões laranja no show da partida.
- Links "Ver"/"Editar" em texto.

## Correção
- **Tradução:**
  - `AdminLabelsHelper` (`admin_match_status_options`, `admin_csv_import_status_options`, `admin_user_enum_options`) é a fonte dos filtros de `matches`, `gestor/matches`, `csv_imports` e `users`. Os rótulos vêm de `StatusBadgeComponent::LABELS`, `CsvImportStatusComponent::STATUS_LABELS` e `activerecord.enums.core/user`.
  - `admin_match_option` e o texto do preview usam o rótulo traduzido.
  - [config/locales/active_admin_resources.pt-BR.yml](../../config/locales/active_admin_resources.pt-BR.yml):
    - Novas chaves: `match_date` (no lugar do `kickoff_at` morto), `round`, `scores_calculated_at`, `shirt_number`, `base_value`, `crest_url`, `rows_processed`, `error_message`, `csv_file`, `email_address`, `owner`, `prize_description` e `first|second|third_place`.
    - Os formulários de campeonato deixam de usar `humanize`.
- **KPIs do Admin:**
  - "Pontuação pendente" → `admin_matches_path(scope: 'encerradas_sem_pontuacao')`.
  - "Campeonatos ativos" conta só campeonatos com alguma partida ainda não pontuada.
  - No Gestor, os KPIs já tinham sido refeitos no 0076 (Partidas hoje, Aguardando scouts, Aguardando finalização).
- **Preview:** o CTA vira "Ir para a finalização", sem parâmetros de placar, com a nota "Na finalização vale o placar dos scouts, não o placar simulado."
- **Papéis de botão:**
  - `admin_match_step_classes` deixa uma única ação primária no show da partida (Admin e Gestor): Scouts antes de haver scouts, Finalizar depois.
  - Preview e Histórico são secondary; "Reverter pontuação" é danger (`bg-loss-solid text-paper`).
  - No show do campeonato, Simulador e Rankings do Esquadrão são secondary.
  - "Recusar pedido" já era danger (0075).
- **Ações de linha do Gestor:** `admin_icon_action_link` em `bolao_scoring_rules`, `esquadrao_lineups`, `players`, `pools` e `teams`.
- **CSV:** legend "Arquivo CSV", com as colunas esperadas no hint. Status traduzido no index. O show renderiza `Ui::CsvImportStatusComponent` (estado `error` quando falhou). O botão de arquivo já vinha estilizado do 0080.
- **Formulários:**
  - A confirmação do placar no finalizador e o motivo da reversão ganham `aria-invalid` e `aria-describedby`, com a mensagem abaixo do campo.
  - Marcador único "(obrigatório)": `Formtastic::FormBuilder.required_string` e `admin_required_label` no finalizador, na reversão, no preview e na recusa de gestor.
  - `match_date` do Gestor vira `datetime_picker` (`<input type="datetime-local">`).
  - O comentário ganha o rótulo "Novo comentário".
  - Colunas numéricas (camisa, valor base, pontos das regras, rodada, linhas processadas, rankings) ficam alinhadas à direita com `tabular-nums`.
- **Termos:**
  - O Admin ganha o item de topo "Campeonatos"; o Gestor mantém "Meus campeonatos", porque lá o campeonato é dele.
  - "Pontuação do Bolão" → "Regras do Bolão".
  - Cards do Gestor: "Agendar partida" e "Editar campeonato".
- **Estados vazios:**
  - O dashboard usa o vazio do `AdminTableComponent`; a lista de pendentes de pontuação virou tabela.
  - Rankings e preview usam `Ui::EmptyStateComponent`.
- **Legend:** `.fieldset-title` já tinha `border-rule` (conferido no navegador: `rgb(217, 211, 196)`). `Ui::FormSectionComponent` e `PreviewPanelComponent` continuam fora de uso: os formulários do ActiveAdmin usam fieldsets do Formtastic, e trocar isso não está no escopo.
- Os ícones do menu e dos KPIs saíram de `AdminHelper` para `AdminIconsHelper`.

## Evidência
- Navegador (Playwright):
  - Partida ao vivo: Scouts laranja; Preview, Finalizar e Histórico brancos.
  - Dashboard: "Pontuação pendente".
  - Nova partida do Gestor com `datetime-local` e "(obrigatório)".
- `spec/requests/admin/consistency_spec.rb`; `navigation_spec`, `dashboard_spec`, `form_spec` e `bolao_preview_spec` atualizados.

## Pronto quando
- Nenhum status/atributo cru nas telas cobertas
- Gate `test` verde
