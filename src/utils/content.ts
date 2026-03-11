// src/utils/content.ts — helpers para content collections
import { getCollection } from 'astro:content';

/** Retorna posts de blog publicados, ordenados do mais recente. */
export async function getPublishedPosts() {
  const posts = await getCollection('blog', ({ data }) => !data.draft);
  return posts.sort(
    (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf(),
  );
}

/** Retorna TILs publicados, ordenados do mais recente. */
export async function getPublishedTils() {
  const tils = await getCollection('til', ({ data }) => !data.draft);
  return tils.sort(
    (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf(),
  );
}

/** Retorna projects, ordenados por featured e depois por data. */
export async function getProjects() {
  const projects = await getCollection('projects');
  return projects.sort((a, b) => {
    if (a.data.featured && !b.data.featured) return -1;
    if (!a.data.featured && b.data.featured) return 1;
    return b.data.pubDate.valueOf() - a.data.pubDate.valueOf();
  });
}

/** Extrai todas as tags únicas de uma lista de posts. */
export function getAllTags(
  posts: Array<{ data: { tags: string[] } }>,
): string[] {
  const tags = posts.flatMap((p) => p.data.tags);
  return [...new Set(tags)].sort();
}
