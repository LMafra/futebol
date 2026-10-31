# Design Critique 0001 — grill de `0001-direction.md`

Modo batch: perguntas com resposta recomendada adotada como default (revisar com o time).

## Auditoria anti-AI
| item | veredito | nota |
|---|---|---|
| Gradiente roxo/rosa/violeta | ok | nenhum gradiente |
| Glassmorphism | ok | proibido explícito |
| Hero 3-cards-ícones | ok | admin 8/4, 3/9 |
| Gradient text | ok | — |
| Emoji decorativo | ok | SVG Lucide/Heroicons |
| Glow/neon | ok | — |
| Sombras coloridas | ok | rgb(22 22 22) neutro |
| Inter/Roboto só | ok | Fraunces + Source Sans 3 |
| "Powered by AI" | ok | — |
| Contraste editorial | ok | serif × sans + fio 3px |
| Fotos/brasões reais | ok | R2 + crédito |
| **Acento único 60-30-10** | **violação (1)** | `loss` #A4161A + `win` = 2º/3º croma saturado em ranking; compete com laranja |
| Numerais tabulares | ok | — |
| Espaço negativo | ok | fora do scoreboard |
| Referência BR | ok | Placar, Lance!, mesa redonda |

**Total: 1 violação (≤1 → pass)**

## Grill (design tree, rodada 1)
- **Q1 Estados win/draw/loss**: reduzir para glifos V/E/D em `ink` + fundo `pitch` 12%/`rule`/`loss` 12% (tint, não sólido)? ➡ sim
- **Q2 `win` = `pitch`**: mesma cor para estrutura e vitória confunde semântica; usar tint `pitch/15` para win? ➡ sim
- **Q3 Verde+laranja**: risco de lembrar marca de clube específico/patrocinador; aceitar com brasões reais dominando? ➡ sim
- **Q4 Fraunces em tabela**: proibir Fraunces abaixo de 20px (só display)? ➡ sim
- **Q5 Modo noite**: scoreboard `night` também no admin? ➡ não, só TV/telão
- **Q6 Licença de brasões/fotos**: fonte licenciada (agência) antes de produção; placeholder = silhueta P&B, nunca ilustração IA? ➡ sim
- **Q7 Laranja "AO VIVO"**: pulsar? ➡ não; badge estático, motion só em mudança de placar (150ms)

## Ações para a Spec (Fase 3)
- Tokens `win/draw/loss` como tints (≤15% opacidade) + glifo
- Fraunces mínimo 20px; tabelas 100% Source Sans 3
- Placeholder de imagem P&B
