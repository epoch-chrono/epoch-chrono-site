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

Edit `src/pages/now.astro` directly — it's a static page, no content collection.

Update the `updatedAt` const at the top and the content inside the `<section>` blocks:

```astro
const updatedAt = '2026-03';  // ← atualizar aqui
```

Add or edit sections in the format:

```astro
<section class="space-y-2">
  <h2 ...>trabalho</h2>
  <p>Descrição do que está acontecendo agora.</p>
</section>
```

---

### /uses page

Edit `src/pages/uses.astro` directly — também é página estática.

Update the `stack` array at the top of the file:

```astro
const stack = [
  { category: 'infra & cloud', items: ['AWS', 'Cloudflare', 'Vercel'] },
  { category: 'editor & terminal', items: ['Helix', 'Fish shell', 'Ghostty'] },
  // adicionar ou remover categorias aqui
];
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

## License

Content (posts, notes) © Vitor Jr — all rights reserved.
Code (components, config) — [MIT](LICENSE).
