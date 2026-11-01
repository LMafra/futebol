# Documentação do Futebol

## Arquitetura e decisões
- [ADR 0001 — Arquitetura geral](adr/0001-arch.md)
- [ADR 0002 — ActiveAdmin × Rails 8.1](adr/0002-activeadmin-rails81.md)
- [ADR 0003 — Simulador: classificação "e se"](adr/0003-simulador.md)
- [ADR 0004 — Bolão: pontuação em 2 faixas configuráveis](adr/0004-bolao-scoring.md)
- [Spec consolidada (v3)](spec-v3.md)
- [Glossário](glossary.md)

## Produto e design
- [Direção de design](design/0001-direction.md)
- [Crítica de design](design/0001-critique.md)

## Desenvolvimento
- [Regras para agentes](agents.md)
- [Tickets (índice)](tickets/INDEX.md)
- [Checkpoints de execução](checkpoints/STATUS.md)

## Operações
- [MCPs configurados](mcp/README.md)
- [Guia de operações](OPERATIONS.md)
  - [Deploy (Render + Supabase)](OPERATIONS.md#deploy-render--supabase)
  - [Storage (Cloudflare R2)](OPERATIONS.md#storage-cloudflare-r2)
  - [E-mail (Resend)](OPERATIONS.md#e-mail-resend)
  - [Keep-alive](OPERATIONS.md#keep-alive)
  - [Observabilidade (OpenTelemetry → OpenObserve self-hosted)](OPERATIONS.md#observabilidade-opentelemetry--openobserve)
- [Infraestrutura de produção (resumo no README)](../README.md#infraestrutura-de-produção)
- [Qualidade e ferramentas](QUALITY.md)
