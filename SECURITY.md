# Política de segurança

## Versões suportadas

Só a branch `main` (o que está em produção no Render) recebe correções de segurança.

## Como reportar uma vulnerabilidade

Não abra issue pública. Use o reporte privado do GitHub: aba **Security → Report a vulnerability** em [LMafra/futebol](https://github.com/LMafra/futebol/security/advisories/new).

Inclua:

- o que é afetado (rota, job, engine) e o impacto (vazamento de dados, escalada para admin, etc.);
- passos para reproduzir, de preferência contra o ambiente local (`bin/rails db:seed` cria usuários demo);
- versão/commit testado.

Prazos: confirmação de recebimento em até 3 dias úteis e avaliação inicial em até 7. Correções críticas saem como patch na `main`, e o advisory é publicado depois do deploy.

## Escopo

- Dentro: a aplicação Rails (engines `core`, `bolao`, `cartola`, `simulador`), o admin (`/admin`, `/admin/jobs`), `render.yaml` e o workflow de CI.
- Fora: contas e senhas demo (`*@demo.local`, públicas por design e criadas só em development/test), DoS volumétrico contra o plano free do Render e vulnerabilidades em serviços de terceiros (Render, provedor de Postgres, Cloudflare R2, Resend). Estas devem ir para o fornecedor.

## O que o projeto já faz

- CI: Brakeman, `bundler-audit check --update` e `gitleaks detect` em todo PR; Dependabot semanal (bundler e GitHub Actions).
- `.githooks/pre-commit` bloqueia secrets no commit; segredos ficam no dashboard do Render, nunca no repositório.
- Autorização via Pundit (inclusive no ActiveAdmin) e rate limit nos endpoints de autenticação.
