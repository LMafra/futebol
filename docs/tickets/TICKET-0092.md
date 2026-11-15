# TICKET-0092 — Modalidade, rascunho e assistente de cadastro em etapas

- Deps: TICKET-0090, TICKET-0091
- Skill: [W]tdd, migration
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 ([ADR 0006](../adr/0006-gestor-times-lances.md), Modalidade e rascunho)

## Descrição
- **Sem modalidade:** o campeonato não dizia como era jogado. Society, futsal e futevôlei usavam os mesmos limites de Esquadrão do campo.
- **Publicado ao salvar:** um campeonato pela metade já aparecia na home, na página pública e no Simulador.
- **Etapas só visuais:** o assistente do TICKET-0077 escondia seções no navegador, mas enviava tudo em um único POST. Um erro só aparecia no fim, e não havia revisão antes de publicar.

## Ambiente
- Celular 390px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`)

## Severidade
Média: campeonatos incompletos ficavam visíveis, e os limites do Esquadrão não serviam para outras modalidades.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/championships/new`.
2. Preencher só o nome e a temporada e salvar.
3. Abrir a home sem login.

## Esperado
O campeonato fica em rascunho até a revisão. O gestor escolhe a modalidade, e os limites do Esquadrão vêm dela.

## Atual
O campeonato aparece na home na hora, com os limites do futebol de campo.

## Correção
- **Modalidade** (`Core::Championship::MODALITY`):
  - Tipo: Campo, Society, Futsal ou Futevôlei;
  - Gênero: Masculino, Feminino ou Misto;
  - Categoria: Infantil, Base, Adulto ou Master;
  - Nível: Amador ou Profissional.
  - Strings com enum e `check_constraint` no banco. Os campeonatos existentes ficam como Campo · Masculino · Adulto · Amador.
  - No rascunho, trocar o Tipo aplica os limites sugeridos do Esquadrão (`CARTOLA_DEFAULTS`). Depois de publicado, os limites não mudam sozinhos.
- **Rascunho:**
  - `status` `draft`/`published`; os existentes ficam publicados.
  - `publicly_visible` e `latest` ignoram rascunhos. Por isso a página pública, a home e o Simulador não mostram rascunhos, nem para quem está logado.
  - A escalação, os rankings do Esquadrão e o seletor de bolão também consultam só campeonatos publicados.
- **Assistente em etapas no servidor** (`ChampionshipWizardHelper`, `ChampionshipWizardActions`, `AdminChampionshipForm`), igual no Admin e no Gestor:
  - Etapas: Dados → Modalidade → Esquadrão → Premiação → Revisão, cada uma com uma frase dizendo por que vem ali.
  - Dados cria o rascunho. Cada etapa seguinte salva antes de abrir a próxima, e um erro volta para a própria etapa.
  - Esquadrão mostra a sugestão da modalidade ("1 goleiro, 2 defensores…"). Os campos ficam em "Opções avançadas".
  - Revisão resume as etapas com "Editar …" em cada uma e explica onde ficam os bolões e as regras. "Publicar campeonato" publica.
  - Navegação com `aria-current="step"`; as etapas já salvas viram links.
  - Depois de publicado, a edição volta a ser uma página única com todas as seções.
  - O Stimulus `form_wizard_controller.js` saiu.
- **Admin e Gestor:**
  - coluna e filtro "Situação" (rascunho/publicado) na lista;
  - Modalidade e Situação na página do campeonato;
  - "Continuar rascunho" na página e no painel do gestor.

## Evidência
- `spec/models/core/championship_spec.rb`, `spec/requests/admin/championship_wizard_spec.rb`, `spec/requests/championships_spec.rb`, `spec/requests/simulador_spec.rb`, `spec/requests/gestor/namespace_spec.rb`
- Playwright 390px (gestor): criação em 5 etapas. `/campeonatos/:id` dá 404 no rascunho e 200 depois de "Publicar campeonato".

## Pronto quando
- [x] Modalidade com 4 campos e limites sugeridos por tipo
- [x] Rascunho fora do site público até publicar
- [x] Assistente em etapas salvas no servidor, com revisão, no Admin e no Gestor
