# epoch-chrono

Personal site — [epoch-chrono.com](https://epoch-chrono.com)

Blog, TIL, projects and notes by [Vitor Jr](https://epoch-chrono.com/about) — SRE & platform engineer.

## Stack

- **Framework:** [Astro](https://astro.build) (SSG)
- **Styling:** [Tailwind CSS v4](https://tailwindcss.com)
- **Content:** Markdown / MDX — no CMS
- **Deploy:** [Vercel](https://vercel.com)
- **DNS:** [Cloudflare](https://cloudflare.com)
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
│   └── projects/   # nome-projeto.md
├── layouts/        # BlogPost, TilPost, Project
├── pages/          # Routes
├── styles/         # global.css
└── utils/          # date.ts, content.ts
```

## Content collections

| Collection | Path | Format |
| :--------- | :--- | :----- |
| blog | `src/content/blog/` | Markdown / MDX |
| til | `src/content/til/` | Markdown |
| projects | `src/content/projects/` | Markdown |

## License

Content (posts, notes) © Vitor Jr — all rights reserved.
Code (components, config) — [MIT](LICENSE).
