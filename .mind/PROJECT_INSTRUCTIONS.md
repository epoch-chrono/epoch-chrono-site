# Instruções do projeto epoch-chrono

> Versão completa com credenciais em `PROJECT_INSTRUCTIONS.claude.md` (não commitado, apenas no Claude App).

## Pasta raiz

```text
$HOME/Git/OpenCodeSpace/personal/epoch-chrono
```

> **Este projeto é trabalhado diretamente com Claude** — não usa fluxo OpenCode/handover.

## Sobre o projeto

Site pessoal/profissional em Astro (SSG). Engloba:

- Landing page + about (posicionamento como SRE / platform engineer)
- Blog técnico (posts, postmortems, decisões de arquitetura, opinião)
- TIL — Today I Learned (posts curtos, alta cadência)
- Projects / OSS (showcase de projetos open source)
- Uses / Stack (ferramentas, setup, workflow)
- /now page

Documentos complementares (em `.mind/`):

- [`CONTENT_CONVENTIONS.md`](./.mind/CONTENT_CONVENTIONS.md) — frontmatter, categorias, TIL
- [`FOLDER_STRUCTURE.md`](./.mind/FOLDER_STRUCTURE.md) — estrutura de pastas Astro
- [`WRITING_WORKFLOW.md`](./.mind/WRITING_WORKFLOW.md) — drafts, publicação, newsletter
- [`DESIGN_SYSTEM.md`](./.mind/DESIGN_SYSTEM.md) — paleta, tipografia, componentes, favicon

## Variables

> Valores reais definidos em `.envrc` (não commitado).
> Ver `.envrc.example` para lista completa de variáveis necessárias.

```bash
# Identidade
SITE_DOMAIN='epoch-chrono.com'
SITE_AUTHOR='Vitor Jr'
EMAIL_AUTHOR='vitor@epoch-chrono.com'
GITHUB_ORG='epoch-chrono-com'
GITHUB_USER='epoch-chrono'
GITHUB_REPO='https://github.com/epoch-chrono/epoch-chrono'

# Deploy — Vercel
VERCEL_API_TOKEN=        # ver .envrc
VERCEL_PROJECT='epoch-chrono'

# DNS — Cloudflare (domínio epoch-chrono.com)
CLOUDFLARE_API_TOKEN=    # ver .envrc
CLOUDFLARE_ZONE_ID=      # ver .envrc
CLOUDFLARE_ACCOUNT_ID=   # ver .envrc

# Analytics — Cloudflare Web Analytics
PUBLIC_CF_ANALYTICS_TOKEN=  # ver .envrc

# Newsletter — Buttondown
BUTTONDOWN_API_KEY=      # ver .envrc
BUTTONDOWN_API='https://api.buttondown.email/v1'

# Notion (conta pessoal Epoch)
NOTION_API_TOKEN=        # ver .envrc
NOTION_BASE_PAGE='https://www.notion.so/epoch-chrono/epoch-chrono-com-site-320490af342d80e7a352d52661aad5a9'

# GitHub (org epoch-chrono — para Actions, releases, gists)
GITHUB_API_TOKEN=        # ver .envrc

# === OnePassword === #
export SSH_AUTH_SOCK=''
```

## Tooling

### Deploy & Hosting

- **Vercel** — projeto `epoch-chrono` já conectado ao repo GitHub
- Preview automático por PR; deploy de produção em push para `main`
- Domínio `epoch-chrono.com` gerenciado na **Cloudflare** (DNS aponta para Vercel)
- CNAME no CF: `epoch-chrono.com → cname.vercel-dns.com` (proxy **desligado** — DNS only, senão quebra SSL da Vercel)

### Analytics

- **Cloudflare Web Analytics** — ativar em dash.cloudflare.com → zona epoch-chrono.com → Web Analytics
- Inserir beacon snippet no `<head>` via componente `SEO.astro`
- Zero cookies, zero GDPR, gratuito

### Stack

```text
Runtime:     Node.js (gerenciado via mise)
Framework:   Astro (SSG)
Conteúdo:    Markdown / MDX (arquivos no repo, sem CMS)
Styling:     Tailwind CSS
Deploy:      Vercel
DNS:         Cloudflare
Analytics:   Cloudflare Web Analytics
Comentários: Giscus (GitHub Discussions) — adicionar quando necessário
Newsletter:  Buttondown
```

### Git

```bash
# Remote origin: org epoch-chrono no GitHub
# Repo: https://github.com/epoch-chrono/epoch-chrono-site
# Branch principal: main — PROTEGIDA pelo pre-commit hook no-commit-to-branch
# NUNCA commitar direto em main. SEMPRE criar branch antes.

# Fluxo obrigatório:
git checkout -b <type>/<descricao>
git add .
git cz
git push origin <branch>
gh pr create --title "..." --body "" --base main --head <branch> \
  && gh pr merge (gh pr list --repo epoch-chrono/epoch-chrono-site --state open --json number -q '.[].number') --merge --delete-branch

### Mise (gerenciamento de versões)

```bash
mise use node@lts
mise use pnpm@latest
```

## Convenções

- Código e docs em inglês; posts em pt-BR ou en dependendo do público-alvo do post
- Commits em inglês, formato Conventional Commits (`feat:`, `fix:`, `content:`, `chore:`)
- Nunca mencionar nomes de AI tooling em posts, commits, PRs
- Frontmatter e convenções de conteúdo: ver `CONTENT_CONVENTIONS.md`
- Todo projeto: `.envrc` com `source_up`, adicionado ao `.gitignore`
- Backup e plano de rollbacks OBRIGATÓRIOS antes de qualquer alteração destrutiva
  - Pasta de backups: `$HOME/Git/OpenCodeSpace/personal/backups-and-rollbacks/epoch-chrono/`
  - Subpasta: `{nome-atividade}/{%Y%m%d-%H%M}/`

## Outros

- TODA alteração (change, delete, update) em qualquer recurso: 1. Backup prévio, 2. Plano de rollback
- Timestamps em BRT (UTC-3)
- Títulos de conversa: `{YYYYMMDD-HHmm}-{ProjetoSlug}-{DescricaoCurta}` onde slug = `epoch-chrono`
- Tracking: GitHub Issues no repo [epoch-chrono/epoch-chrono-site](https://github.com/epoch-chrono/epoch-chrono-site)
- Posts rascunho: nunca commitar com `draft: false` sem revisão
