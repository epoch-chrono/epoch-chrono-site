import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    lang: z.enum(['pt-BR', 'en']).default('pt-BR'),
    draft: z.boolean().default(true),
    tags: z.array(z.string()).default([]),
    categories: z.array(z.string()).default([]),
    hero: z
      .object({
        image: z.string(),
        alt: z.string(),
      })
      .optional(),
    canonical: z.string().url().optional(),
  }),
});

const til = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    pubDate: z.coerce.date(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
  }),
});

const projects = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    status: z.enum(['active', 'archived', 'wip']).default('active'),
    repo: z.string().url().optional(),
    demo: z.string().url().optional(),
    tags: z.array(z.string()).default([]),
    featured: z.boolean().default(false),
    pubDate: z.coerce.date(),
  }),
});

export const collections = { blog, til, projects };
