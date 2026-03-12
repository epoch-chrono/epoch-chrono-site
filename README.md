# epoch-chrono

Personal site — [epoch-chrono.com](https://epoch-chrono.com)

Blog, TIL, projects and notes by [Vitor Jr](https://epoch-chrono.com) — SRE & platform engineer.

## Stack

- **Framework:** [Astro v6](https://astro.build) (SSG)
- **Styling:** [Tailwind CSS v4](https://tailwindcss.com)
- **Content:** Markdown / MDX — no CMS
- **Deploy:** [Vercel](https://vercel.com) (auto-deploy on push to `main`)
- **DNS:** [Cloudflare](https://cloudflare.com) (proxy off — DNS only)
- **Analytics:** Cloudflare Web Analytics (zero cookies)
- **Newsletter:** [Buttondown](https://buttondown.email)

## Development

```sh
# Install dependencies
pnpm install

# Start dev server at localhost:4321
pnpm dev

# Build for production
pnpm build

# Preview production build
pnpm preview
```

## Project structure

```text
src/
├── components/
│   ├── layout/     # BaseLayout, Header, Footer
│   ├── blog/       # PostCard, TagList
│   ├── til/        # TilCard
│   └── common/     # SEO
├── content/
│   ├── blog/       # YYYY-MM-DD-slug.md
│   ├── til/        # YYYY-MM-DD-slug.md
│   └── projects/   # project-name.md
├── content.config.ts   # Astro v6 content collections (glob loader)
├── layouts/        # BlogPost, TilPost, Project
├── pages/          # Routes
├── styles/         # global.css
├── utils/          # date.ts, content.ts
public/
├── assets/         # Static images (photos, etc.)
├── og/             # OpenGraph images
└── favicon.*       # favicon.svg, favicon.ico, favicon-512.png
```

## Updating content

### Blog post

Create a new file in `src/content/blog/`:

```sh
touch src/content/blog/YYYY-MM-DD-slug-do-post.md
```

Frontmatter mínimo:

```yaml
---
title: "Título do post"
description: "Resumo curto"
pubDate: 2026-03-11
tags: ["sre", "kubernetes"]
draft: false
---
```

See [`.mind/CONTENT_CONVENTIONS.md`](.mind/CONTENT_CONVENTIONS.md) for full schema.

---

### TIL (Today I Learned)

Create a new file in `src/content/til/`:

```sh
touch src/content/til/YYYY-MM-DD-slug.md
```

Frontmatter mínimo:

```yaml
---
title: "O que aprendi hoje"
pubDate: 2026-03-11
tags: ["linux", "git"]
---
```

---

### /now page

Edit `src/content/now/index.md` — plain Markdown, no Astro/JSX.

Update `updatedAt` in the frontmatter and edit the sections using standard headings:

```markdown
---
updatedAt: '2026-03'
---

## trabalho

Descrição do que está rolando no trabalho agora.

## lendo

Título do livro.
```

---

### /uses page

Edit `src/content/uses/index.md` — plain Markdown, no Astro/JSX.

Add, remove or rename categories using headings and lists:

```markdown
## editor & terminal

- Helix
- Fish shell
- Ghostty
- zellij
```

---

### Projects

Create a new file in `src/content/projects/`:

```sh
touch src/content/projects/nome-do-projeto.md
```

Frontmatter mínimo:

```yaml
---
title: "Nome do Projeto"
description: "O que ele faz"
url: "https://github.com/..."
tags: ["go", "cli"]
---
```

---

## Content collections

| Collection | Path | Format |
| :--------- | :--- | :----- |
| blog | `src/content/blog/` | Markdown / MDX |
| til | `src/content/til/` | Markdown |
| projects | `src/content/projects/` | Markdown |

See [`.mind/CONTENT_CONVENTIONS.md`](.mind/CONTENT_CONVENTIONS.md) for frontmatter schema and writing conventions.

## Versioning

This project uses two independent versioning concepts.

### epochVersion — site version

Tracks the overall site as a software artifact. Lives in `package.json` and git tags.

```json
{ "version": "0.1.0" }
```

Displayed automatically in the footer of every page (`© 2026 Vitor Jr · v0.1.0`).

To bump and release:

```sh
./bin/tag-release.fish [major|minor|patch]
# default: patch
# bumps package.json, commits, creates annotated git tag, pushes both
```

Semver intent:
- `patch` — bug fixes, small UI tweaks, dependency updates
- `minor` — new features, new sections, significant content additions
- `major` — full redesigns, breaking changes to structure

### postVersion — content version

Tracks the version of an individual post or project page. Optional field in frontmatter.

```yaml
---
postVersion: "1.0.0"
---
```

Displayed in the footer of the post/project page when present (`post v1.0.0`).

Semver intent:
- `1.0.0` — first published version
- `1.1.0` — minor corrections, added sections, updated examples
- `2.0.0` — significant rewrite or restructure

Posts without `postVersion` show no version in the footer — omit for drafts or when not relevant.

---

## Git flow

`main` is protected — never commit directly.

```sh
git checkout -b <type>/<description>
git add .
git cz
git push origin <branch>
gh pr create --title "..." --body "" --base main --head <branch>
gh pr merge <number> --merge --delete-branch
```

Commit types: `feat`, `fix`, `content`, `chore`, `docs`.

## Session continuity

This project uses a protocol to preserve context between Claude sessions. State is stored in `.mind/HANDOVER.md` (gitignored — never committed).

See [`.mind/CONTINUIDADE.md`](.mind/CONTINUIDADE.md) for the full protocol and specs in [`.mind/commands/`](.mind/commands/).

### Modes of operation

**With Desktop Commander** (local session — extension active):

- Files read directly via `read_file(/Users/maxter/Git/OpenCodeSpace/personal/epoch-chrono-site/.mind/<file>)`
- Commands executed via `start_process`
- Credentials available at runtime via `.envrc`

**Without Desktop Commander** (claude.ai web, no extension):

- Artifacts fetched via `web_fetch` on raw GitHub URLs
- Repo is public — no authentication needed
- No cloning required — `.mind/` files are read directly via raw URL
- Entry point: `web_fetch(https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/CONTEXT.md)`

### Reading context on demand

Most `.mind/` docs are fetched live from the repo when needed. Examples of how to request them at the start of a conversation:

```text
leia o design system do projeto
→ web_fetch: .mind/DESIGN_SYSTEM.md

vou criar um novo post, leia as convenções de conteúdo
→ web_fetch: .mind/CONTENT_CONVENTIONS.md

quero publicar um post, leia o writing workflow
→ web_fetch: .mind/WRITING_WORKFLOW.md

vou mexer em componentes, leia a estrutura de pastas
→ web_fetch: .mind/FOLDER_STRUCTURE.md

qual o protocolo de sessão? leia o CONTEXT.md
→ web_fetch: .mind/CONTEXT.md
```

All URLs are in [`.mind/CONTEXT.md`](.mind/CONTEXT.md).

---

### `[mind-read]` — início de sessão

Use sempre ao iniciar uma conversa nova para verificar se há contexto acumulado de sessões anteriores.

```text
[mind-read]
```

**Quando usar:**

- Toda vez que iniciar uma nova conversa sobre o projeto
- Antes de retomar trabalho interrompido
- Para saber de onde parou sem precisar re-explicar

**Output:** resumo do `HANDOVER.md` ativo, ou aviso de que não há workflow em curso.

---

### `[mind-save]` — checkpoint intermediário

Persiste o estado atual da sessão em `.mind/HANDOVER.md`. Acumula contexto — cada save faz append, nunca sobrescreve.

```text
[mind-save]
```

**Quando usar:**

- Após um PR ser mergeado
- Após uma decisão técnica ou arquitetural relevante
- Ao pausar o trabalho no meio de uma feature
- Antes de mudar de assunto dentro da mesma sessão

**Exemplo de situação:**

```text
# mergeou PR #12, vai continuar depois
[mind-save]
# → salva: o que foi feito, PR mergeado, próximo passo pendente
```

---

### `[mind-snapshot]` — encerramento de sessão

Gera um artefato completo de handoff com git log, decisões, riscos e próximos passos priorizados. Apaga o `HANDOVER.md` ao final — o snapshot o substitui.

```text
[mind-snapshot]
```

**Quando usar:**

- Ao encerrar uma sessão de trabalho
- Quando o contexto acumulado precisa ser consolidado antes de continuar amanhã
- Ao final de um ciclo maior (ex: feature completa, refactor, sprint)

**Exemplo de situação:**

```text
# fim do dia, trabalho em andamento
[mind-snapshot]
# → gera snapshot estruturado com tudo
# → deleta HANDOVER.md
# → na próxima sessão: [mind-read] carrega o snapshot
```

---

### `[mind-clear]` — encerramento de ciclo

Limpa o workflow ativo. Usar apenas quando o ciclo de trabalho está realmente concluído e o snapshot já foi gerado.

```text
[mind-clear]
```

**Quando usar:**

- Após `[mind-snapshot]`, quando o trabalho está 100% concluído
- Para resetar o estado antes de iniciar um ciclo novo e não relacionado

**Fluxo correto:**

```text
[mind-snapshot]   ← consolida tudo
      ↓
[mind-clear]      ← limpa estado ativo
      ↓
nova sessão → [mind-read] → "sem workflow ativo"
```

> Nunca usar `[mind-clear]` sem antes rodar `[mind-snapshot]`, a menos que o trabalho não precise de continuidade.

---

## AI context sync

This project uses the **claude.ai GitHub connector** — all repo files are synced automatically on every push.

Only one file requires manual upload (contains credentials, gitignored):

| File | Target | When to re-upload |
| :--- | :----- | :---------------- |
| `.mind/PROJECT_INSTRUCTIONS.claude.md` | Project Instructions | After running `gen-claude-instructions` (instructions or `.envrc` changed) |

Everything else (including all `.mind/` files) is kept in sync automatically via the GitHub connector.

To regenerate `PROJECT_INSTRUCTIONS.claude.md` from source:

```sh
gen-claude-instructions        # requires PATH_add bin in .envrc
# or
./bin/gen-claude-instructions
```

> `PROJECT_INSTRUCTIONS.claude.md` is gitignored (contains credentials).
> `PROJECT_INSTRUCTIONS.md` is the canonical source — edit this, never the generated file.

---

## License

Content (posts, notes) © Vitor Jr — all rights reserved.
Code (components, config) — [MIT](LICENSE).
