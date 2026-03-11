---
title: "TIL: Astro v6 mudou a API de content collections"
pubDate: 2026-03-11
tags:
  - astro
  - typescript
draft: false
---

No Astro v6 o arquivo de configuração das content collections mudou de
`src/content/config.ts` para `src/content.config.ts` (raiz do `src/`).

Além disso, cada collection precisa de um `loader` explícito:

```ts
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/blog' }),
  schema: z.object({ ... }),
});
```

Sem o loader, o build lança `LegacyContentConfigError`.
